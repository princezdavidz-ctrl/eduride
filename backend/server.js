import { createServer } from "node:http";
import { pathToFileURL } from "node:url";
import pg from "pg";
import { createSessionToken, hashPassword, hashSessionToken, normalizeEmail, publicUser, verifyPassword } from "./security.js";

const { Pool } = pg;
const PORT = Number(process.env.PORT || 8787);
const APP_BASE_PATH = (process.env.APP_BASE_PATH || "").replace(/\/+$/, "");
const BODY_LIMIT_BYTES = 16 * 1024;
const allowedOrigins = new Set((process.env.CORS_ORIGIN || "").split(",").map((value) => value.trim()).filter(Boolean));
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_SSL === "true" ? { rejectUnauthorized: true } : undefined,
  max: Number(process.env.DB_POOL_MAX || 10),
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 5_000,
});
const loginAttempts = new Map();

function sendJson(response, status, payload, origin) {
  const headers = {
    "content-type": "application/json; charset=utf-8",
    "cache-control": "no-store",
    "x-content-type-options": "nosniff",
    "referrer-policy": "no-referrer",
    "access-control-allow-headers": "content-type, authorization, x-device-token",
    "access-control-allow-methods": "GET, POST, PATCH, OPTIONS",
    vary: "Origin",
  };
  if (origin) headers["access-control-allow-origin"] = origin;
  response.writeHead(status, headers);
  response.end(JSON.stringify(payload));
}

function readBody(request) {
  return new Promise((resolve, reject) => {
    let body = "";
    let settled = false;
    request.on("data", (chunk) => {
      if (settled) return;
      body += chunk;
      if (Buffer.byteLength(body) > BODY_LIMIT_BYTES) {
        settled = true;
        reject(new Error("Request body too large"));
      }
    });
    request.on("end", () => {
      if (settled) return;
      try {
        const value = body ? JSON.parse(body) : {};
        if (!value || typeof value !== "object" || Array.isArray(value)) throw new Error("JSON body must be an object");
        resolve(value);
      } catch {
        reject(new Error("Invalid JSON request"));
      }
    });
    request.on("error", (error) => {
      if (!settled) reject(error);
    });
  });
}

function isUuid(value) {
  return typeof value === "string" && /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}

function isRateLimited(key) {
  const now = Date.now();
  const entry = loginAttempts.get(key);
  if (!entry || now - entry.startedAt > 60_000) {
    loginAttempts.set(key, { startedAt: now, count: 1 });
    return false;
  }
  entry.count += 1;
  return entry.count > 10;
}

async function authenticatedUser(request) {
  const token = request.headers.authorization?.replace(/^Bearer\s+/i, "").trim();
  if (!token || token.length > 256) return undefined;
  const result = await pool.query(
    `SELECT u.* FROM sessions s JOIN users u ON u.id = s.user_id
     WHERE s.token_hash = $1 AND s.expires_at > now()`,
    [hashSessionToken(token)],
  );
  return result.rows[0];
}

async function requireUser(request, reply) {
  const user = await authenticatedUser(request);
  if (!user) reply(401, { error: "Authentication required" });
  return user;
}

function requireRole(user, roles, reply) {
  if (!roles.includes(user.role)) {
    reply(403, { error: "You do not have permission to perform this action" });
    return false;
  }
  return true;
}

function organizationRequired(user, reply) {
  if (!user.organization_id) {
    reply(403, { error: "This account is not assigned to an organization" });
    return false;
  }
  return true;
}

async function visibleBusQuery(user) {
  if (["transport_admin", "school_admin"].includes(user.role)) {
    return {
      sql: "WHERE b.organization_id = $1",
      values: [user.organization_id],
    };
  }
  if (user.role === "driver") {
    return { sql: "WHERE b.driver_id = $1", values: [user.id] };
  }
  return {
    sql: `WHERE EXISTS (
      SELECT 1 FROM child_bus_assignments a
      JOIN children c ON c.id = a.child_id
      WHERE a.bus_id = b.id AND a.active = true AND c.parent_id = $1
    )`,
    values: [user.id],
  };
}

async function listBuses(user) {
  const scope = await visibleBusQuery(user);
  const result = await pool.query(
    `SELECT b.id, b.fleet_number AS "fleetNumber", b.registration_number AS "registrationNumber",
      b.status, COALESCE(r.name, '') AS route, COALESCE(s.name, '') AS school,
      latest.latitude, latest.longitude, latest.recorded_at AS "updatedAt",
      COALESCE(latest.recorded_at >= now() - interval '2 minutes', false) AS "locationFresh",
      NULL::integer AS "etaMinutes"
     FROM buses b
     LEFT JOIN schools s ON s.id = b.school_id
     LEFT JOIN LATERAL (
       SELECT latitude, longitude, recorded_at
       FROM bus_telemetry t WHERE t.bus_id = b.id
       ORDER BY recorded_at DESC LIMIT 1
     ) latest ON true
     LEFT JOIN LATERAL (
       SELECT name FROM routes rt WHERE rt.bus_id = b.id ORDER BY created_at DESC LIMIT 1
     ) r ON true
     ${scope.sql}
     ORDER BY b.fleet_number`,
    scope.values,
  );
  return result.rows.map((bus) => ({
    id: bus.id,
    route: bus.route,
    status: bus.status,
    school: bus.school,
    latitude: bus.latitude,
    longitude: bus.longitude,
    updatedAt: bus.updatedAt,
    locationFresh: bus.locationFresh,
    etaMinutes: bus.etaMinutes,
    fleetNumber: bus.fleetNumber,
    registrationNumber: bus.registrationNumber,
    locationAvailable: bus.latitude !== null && bus.longitude !== null,
  }));
}

async function listAlerts(user, parentScope = false) {
  const values = [user.id];
  let where = "";
  if (["transport_admin", "school_admin"].includes(user.role)) {
    if (!user.organization_id) return [];
    values.push(user.organization_id);
    where = "WHERE a.organization_id = $2";
  } else if (user.role === "driver") {
    where = "WHERE EXISTS (SELECT 1 FROM buses b WHERE b.id = a.bus_id AND b.driver_id = $1)";
  } else if (parentScope) {
    where = `WHERE EXISTS (
      SELECT 1 FROM child_bus_assignments cba
      JOIN children c ON c.id = cba.child_id
      WHERE cba.bus_id = a.bus_id AND cba.active = true AND c.parent_id = $1
    )`;
  } else {
    return [];
  }
  const result = await pool.query(
    `SELECT a.id, a.bus_id AS "busId", a.severity, a.title, a.message,
      a.created_at AS "createdAt", (ar.alert_id IS NOT NULL) AS acknowledged
     FROM alerts a
     LEFT JOIN alert_receipts ar ON ar.alert_id = a.id AND ar.user_id = $1
     ${where}
     ORDER BY a.created_at DESC LIMIT 500`,
    values,
  );
  return result.rows;
}

async function handleRequest(request, response) {
  const origin = request.headers.origin;
  const reply = (status, payload) => sendJson(response, status, payload, origin && allowedOrigins.has(origin) ? origin : undefined);

  if (origin && !allowedOrigins.has(origin)) return reply(403, { error: "Origin is not allowed" });
  if (request.method === "OPTIONS") {
    response.writeHead(204, {
      ...(origin ? { "access-control-allow-origin": origin } : {}),
      "access-control-allow-headers": "content-type, authorization, x-device-token",
      "access-control-allow-methods": "GET, POST, PATCH, OPTIONS",
      "access-control-max-age": "600",
      vary: "Origin",
    });
    return response.end();
  }

  const url = new URL(request.url, "http://localhost");
  let pathname = url.pathname;
  if (APP_BASE_PATH) {
    if (pathname !== APP_BASE_PATH && !pathname.startsWith(`${APP_BASE_PATH}/`)) {
      return reply(404, { error: "Route not found" });
    }
    pathname = pathname.slice(APP_BASE_PATH.length) || "/";
  }

  if (request.method === "GET" && pathname === "/health") {
    try {
      await pool.query("SELECT 1");
      return reply(200, { ok: true, service: "edu-ride-backend", database: "ready" });
    } catch {
      return reply(503, { ok: false, service: "edu-ride-backend", database: "unavailable" });
    }
  }

  if (request.method === "POST" && pathname === "/api/device/telemetry") {
    const deviceToken = request.headers["x-device-token"];
    if (typeof deviceToken !== "string" || deviceToken.length < 32) return reply(401, { error: "Device authentication required" });
    const deviceResult = await pool.query(
      "SELECT id, bus_id FROM devices WHERE token_hash = $1 AND active = true",
      [hashSessionToken(deviceToken)],
    );
    const device = deviceResult.rows[0];
    if (!device) return reply(401, { error: "Invalid device credentials" });
    try {
      const body = await readBody(request);
      const acceptedFields = ["latitude", "longitude", "speedKph", "heading", "recordedAt"];
      if (Object.keys(body).some((field) => !acceptedFields.includes(field))) {
        return reply(400, { error: "Only GPS telemetry is accepted by this endpoint; image payloads are not supported" });
      }
      const latitude = Number(body.latitude);
      const longitude = Number(body.longitude);
      const speedKph = body.speedKph == null ? null : Number(body.speedKph);
      const heading = body.heading == null ? null : Number(body.heading);
      const recordedAt = body.recordedAt ? new Date(body.recordedAt) : new Date();
      if (!Number.isFinite(latitude) || latitude < -90 || latitude > 90 ||
          !Number.isFinite(longitude) || longitude < -180 || longitude > 180 ||
          (speedKph !== null && (!Number.isFinite(speedKph) || speedKph < 0 || speedKph > 250)) ||
          (heading !== null && (!Number.isFinite(heading) || heading < 0 || heading > 360)) ||
          Number.isNaN(recordedAt.getTime()) || recordedAt.getTime() > Date.now() + 60_000 ||
          recordedAt.getTime() < Date.now() - 24 * 60 * 60 * 1000) {
        return reply(400, { error: "Telemetry values are invalid or outside the accepted time window" });
      }
      await pool.query(
        `INSERT INTO bus_telemetry(device_id,bus_id,latitude,longitude,speed_kph,heading,recorded_at)
         VALUES($1,$2,$3,$4,$5,$6,$7)`,
        [device.id, device.bus_id, latitude, longitude, speedKph, heading, recordedAt.toISOString()],
      );
      await pool.query("UPDATE devices SET last_seen_at = now() WHERE id = $1", [device.id]);
      return reply(202, { accepted: true, recordedAt: recordedAt.toISOString() });
    } catch (error) {
      return reply(400, { error: error.message === "Request body too large" ? error.message : "Invalid telemetry payload" });
    }
  }

  if (request.method === "POST" && pathname === "/api/auth/forgot-password") {
    return reply(200, { available: false, message: "Password reset delivery is not configured. Please contact school support." });
  }

  if (request.method === "POST" && pathname === "/api/auth/login") {
    const key = request.socket.remoteAddress || "unknown";
    if (isRateLimited(key)) return reply(429, { error: "Too many sign-in attempts. Try again in one minute." });
    try {
      const body = await readBody(request);
      const email = normalizeEmail(body.email);
      const password = String(body.password ?? "");
      if (!email || !password || password.length > 256) return reply(400, { error: "Email and password are required" });
      const result = await pool.query("SELECT * FROM users WHERE email = $1", [email]);
      const user = result.rows[0];
      if (!user || !(await verifyPassword(password, user.password_hash))) {
        return reply(401, { error: "Invalid email or password" });
      }
      const token = createSessionToken();
      await pool.query(
        "INSERT INTO sessions(token_hash,user_id,expires_at) VALUES($1,$2,now() + interval '8 hours')",
        [hashSessionToken(token), user.id],
      );
      loginAttempts.delete(key);
      return reply(200, { token, user: publicUser(user) });
    } catch (error) {
      return reply(400, { error: error.message === "Request body too large" ? error.message : "Invalid login request" });
    }
  }

  if (request.method === "POST" && pathname === "/api/auth/signup") {
    try {
      const body = await readBody(request);
      const email = normalizeEmail(body.email);
      const name = String(body.name ?? "").trim();
      const password = String(body.password ?? "");
      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || !name || name.length > 120 ||
          password.length < 12 || password.length > 128) {
        return reply(400, { error: "Enter a valid email and name, and use a password of at least 12 characters" });
      }
      const passwordHash = await hashPassword(password);
      const result = await pool.query(
        `INSERT INTO users(email,password_hash,name,role,verification_status)
         VALUES($1,$2,$3,'parent','pending') RETURNING *`,
        [email, passwordHash, name],
      );
      const user = result.rows[0];
      const token = createSessionToken();
      await pool.query(
        "INSERT INTO sessions(token_hash,user_id,expires_at) VALUES($1,$2,now() + interval '8 hours')",
        [hashSessionToken(token), user.id],
      );
      return reply(201, { token, user: publicUser(user) });
    } catch (error) {
      if (error.code === "23505") return reply(409, { error: "An account with this email already exists" });
      return reply(400, { error: error.message === "Request body too large" ? error.message : "Invalid registration request" });
    }
  }

  if (request.method === "POST" && pathname === "/api/auth/logout") {
    const token = request.headers.authorization?.replace(/^Bearer\s+/i, "").trim();
    if (token) await pool.query("DELETE FROM sessions WHERE token_hash = $1", [hashSessionToken(token)]);
    return reply(200, { ok: true });
  }

  let user;
  try {
    user = await requireUser(request, reply);
  } catch (error) {
    console.error("Session lookup failed", error);
    return reply(503, { error: "Authentication service temporarily unavailable" });
  }
  if (!user) return;

  if (request.method === "GET" && pathname === "/api/auth/me") {
    return reply(200, { user: publicUser(user) });
  }

  if (request.method === "GET" && pathname === "/api/profile") {
    return reply(200, { profile: publicUser(user) });
  }

  if (request.method === "PATCH" && pathname === "/api/profile") {
    try {
      const body = await readBody(request);
      const name = body.name === undefined ? user.name : String(body.name).trim();
      const phone = body.phone === undefined ? user.phone : String(body.phone).trim();
      const nationalId = body.nationalId === undefined ? user.national_id : String(body.nationalId).trim();
      if (!name || name.length > 120 || phone.length > 40 || nationalId.length > 80) return reply(400, { error: "Profile values are invalid" });
      const result = await pool.query(
        "UPDATE users SET name=$1, phone=$2, national_id=$3, updated_at=now() WHERE id=$4 RETURNING *",
        [name, phone, nationalId, user.id],
      );
      return reply(200, { profile: publicUser(result.rows[0]) });
    } catch {
      return reply(400, { error: "Invalid profile update" });
    }
  }

  if (request.method === "GET" && pathname === "/api/children") {
    if (user.role !== "parent" && (!requireRole(user, ["transport_admin", "school_admin"], reply) || !organizationRequired(user, reply))) return;
    const result = user.role === "parent"
      ? await pool.query(
          `SELECT c.id,c.name,s.name AS school,c.verification_status AS "verificationStatus"
           FROM children c JOIN schools s ON s.id=c.school_id WHERE c.parent_id=$1 ORDER BY c.created_at DESC`,
          [user.id],
        )
      : await pool.query(
          `SELECT c.id,c.name,s.name AS school,c.verification_status AS "verificationStatus"
           FROM children c JOIN schools s ON s.id=c.school_id
           WHERE s.organization_id=$1 ORDER BY c.created_at DESC`,
          [user.organization_id],
        );
    return reply(200, { children: result.rows });
  }

  if (request.method === "POST" && pathname === "/api/children") {
    if (!requireRole(user, ["parent"], reply)) return;
    try {
      const body = await readBody(request);
      const schoolName = String(body.school ?? "").trim();
      const childName = String(body.name ?? "").trim();
      if (!childName || childName.length > 120 || !schoolName || schoolName.length > 180) return reply(400, { error: "Child name and school are required" });
      const school = await pool.query("SELECT id FROM schools WHERE lower(name)=lower($1) AND active=true ORDER BY created_at LIMIT 1", [schoolName]);
      if (!school.rows[0]) return reply(422, { error: "Select a registered school. Contact your school if it is not listed." });
      const result = await pool.query(
        "INSERT INTO children(parent_id,school_id,name) VALUES($1,$2,$3) RETURNING id,name,verification_status AS \"verificationStatus\"",
        [user.id, school.rows[0].id, childName],
      );
      return reply(201, { child: { ...result.rows[0], school: schoolName } });
    } catch (error) {
      return reply(400, { error: error.message === "Request body too large" ? error.message : "Invalid child details" });
    }
  }

  const childMatch = pathname.match(/^\/api\/children\/([^/]+)$/);
  if (request.method === "PATCH" && childMatch) {
    if (!requireRole(user, ["parent"], reply)) return;
    const childId = decodeURIComponent(childMatch[1]);
    if (!isUuid(childId)) return reply(404, { error: "Child not found" });
    const client = await pool.connect();
    try {
      const body = await readBody(request);
      const schoolName = String(body.school ?? "").trim();
      if (!schoolName) return reply(400, { error: "School is required" });
      await client.query("BEGIN");
      const ownedChild = await client.query(
        "SELECT id FROM children WHERE id=$1 AND parent_id=$2 FOR UPDATE",
        [childId, user.id],
      );
      if (!ownedChild.rows[0]) {
        await client.query("ROLLBACK");
        return reply(404, { error: "Child or registered school not found" });
      }
      const school = await client.query(
        "SELECT id,name FROM schools WHERE lower(name)=lower($1) AND active=true ORDER BY created_at LIMIT 1",
        [schoolName],
      );
      if (!school.rows[0]) {
        await client.query("ROLLBACK");
        return reply(404, { error: "Child or registered school not found" });
      }
      await client.query("DELETE FROM child_bus_assignments WHERE child_id=$1", [childId]);
      const result = await client.query(
        `UPDATE children SET school_id=$1, verification_status='pending', updated_at=now()
         WHERE id=$2 RETURNING id,name,verification_status AS "verificationStatus"`,
        [school.rows[0].id, childId],
      );
      await client.query("COMMIT");
      return reply(200, { child: { ...result.rows[0], school: school.rows[0].name } });
    } catch {
      await client.query("ROLLBACK").catch(() => {});
      return reply(400, { error: "Invalid school change request" });
    } finally {
      client.release();
    }
  }

  if (request.method === "POST" && pathname === "/api/verification") {
    const result = await pool.query(
      "UPDATE users SET verification_status='pending', updated_at=now() WHERE id=$1 RETURNING verification_status",
      [user.id],
    );
    return reply(200, { status: result.rows[0].verification_status, message: "Your profile is waiting for school verification" });
  }
  if (request.method === "GET" && pathname === "/api/verification") {
    return reply(200, { status: user.verification_status });
  }

  if (request.method === "GET" && pathname === "/api/preferences") {
    const result = await pool.query("SELECT value FROM preferences WHERE user_id=$1", [user.id]);
    return reply(200, { preferences: result.rows[0]?.value ?? { language: "English", tripUpdates: true, arrivalAlerts: true } });
  }
  if (request.method === "PATCH" && pathname === "/api/preferences") {
    try {
      const body = await readBody(request);
      const allowed = ["language", "tripUpdates", "arrivalAlerts"];
      if (Object.keys(body).some((key) => !allowed.includes(key))) return reply(400, { error: "Unsupported preference field" });
      const current = await pool.query("SELECT value FROM preferences WHERE user_id=$1", [user.id]);
      const next = { language: "English", tripUpdates: true, arrivalAlerts: true, ...(current.rows[0]?.value ?? {}), ...body };
      if (typeof next.language !== "string" || next.language.length > 40 ||
          typeof next.tripUpdates !== "boolean" || typeof next.arrivalAlerts !== "boolean") return reply(400, { error: "Preference values are invalid" });
      await pool.query(
        `INSERT INTO preferences(user_id,value) VALUES($1,$2::jsonb)
         ON CONFLICT(user_id) DO UPDATE SET value=EXCLUDED.value,updated_at=now()`,
        [user.id, JSON.stringify(next)],
      );
      return reply(200, { preferences: next });
    } catch {
      return reply(400, { error: "Invalid preferences" });
    }
  }

  if (request.method === "GET" && pathname === "/api/buses") {
    if (!["parent", "driver", "school_admin", "transport_admin"].includes(user.role)) return reply(403, { error: "Bus access is not permitted" });
    if (user.role !== "parent" && !organizationRequired(user, reply)) return;
    return reply(200, { buses: await listBuses(user) });
  }

  if (request.method === "GET" && pathname === "/api/schools") {
    const result = ["transport_admin", "school_admin", "driver"].includes(user.role)
      ? (organizationRequired(user, reply) ? await pool.query("SELECT id,name,address,active FROM schools WHERE organization_id=$1 ORDER BY name", [user.organization_id]) : null)
      : await pool.query("SELECT id,name,address,active FROM schools WHERE active=true ORDER BY name");
    if (!result) return;
    return reply(200, { data: result.rows });
  }

  if (request.method === "GET" && pathname === "/api/routes") {
    if (user.role === "parent") {
      const result = await pool.query(
        `SELECT DISTINCT r.id,r.name,r.bus_id AS "busId",r.stops
         FROM routes r JOIN child_bus_assignments a ON a.bus_id=r.bus_id
         JOIN children c ON c.id=a.child_id WHERE c.parent_id=$1 AND a.active=true ORDER BY r.name`,
        [user.id],
      );
      return reply(200, { data: result.rows });
    }
    if (!requireRole(user, ["transport_admin", "school_admin", "driver"], reply) || !organizationRequired(user, reply)) return;
    const result = user.role === "driver"
      ? await pool.query(
          `SELECT r.id,r.name,r.bus_id AS "busId",r.stops FROM routes r
           JOIN buses b ON b.id=r.bus_id WHERE b.driver_id=$1 ORDER BY r.name`,
          [user.id],
        )
      : await pool.query("SELECT id,name,bus_id AS \"busId\",stops FROM routes WHERE organization_id=$1 ORDER BY name", [user.organization_id]);
    return reply(200, { data: result.rows });
  }

  if (request.method === "GET" && pathname === "/api/journeys") {
    if (user.role === "parent") {
      const result = await pool.query(
        `SELECT DISTINCT j.id,j.bus_id AS "busId",r.name AS route,j.departure_at AS "departureAt",
          j.arrival_at AS "arrivalAt",j.status
         FROM journeys j JOIN child_bus_assignments a ON a.bus_id=j.bus_id
         JOIN children c ON c.id=a.child_id LEFT JOIN routes r ON r.id=j.route_id
         WHERE c.parent_id=$1 AND a.active=true ORDER BY j.departure_at DESC LIMIT 500`,
        [user.id],
      );
      return reply(200, { data: result.rows });
    }
    if (!requireRole(user, ["transport_admin", "school_admin", "driver"], reply) || !organizationRequired(user, reply)) return;
    const result = user.role === "driver"
      ? await pool.query(
          `SELECT j.id,j.bus_id AS "busId",r.name AS route,j.departure_at AS "departureAt",
            j.arrival_at AS "arrivalAt",j.status
           FROM journeys j JOIN buses b ON b.id=j.bus_id LEFT JOIN routes r ON r.id=j.route_id
           WHERE b.driver_id=$1 ORDER BY j.departure_at DESC LIMIT 500`,
          [user.id],
        )
      : await pool.query(
          `SELECT j.id,j.bus_id AS "busId",r.name AS route,j.departure_at AS "departureAt",
            j.arrival_at AS "arrivalAt",j.status
           FROM journeys j LEFT JOIN routes r ON r.id=j.route_id
           WHERE j.organization_id=$1 ORDER BY j.departure_at DESC LIMIT 1000`,
          [user.organization_id],
        );
    return reply(200, { data: result.rows });
  }

  if (request.method === "GET" && (pathname === "/api/alerts" || pathname === "/api/notifications")) {
    const isNotifications = pathname === "/api/notifications";
    if (!isNotifications && (!requireRole(user, ["transport_admin", "school_admin"], reply) || !organizationRequired(user, reply))) return;
    return reply(200, isNotifications
      ? { notifications: await listAlerts(user, true) }
      : { data: await listAlerts(user) });
  }

  const alertMatch = pathname.match(/^\/api\/alerts\/([^/]+)$/);
  if (request.method === "PATCH" && alertMatch) {
    if (!requireRole(user, ["transport_admin", "school_admin"], reply) || !organizationRequired(user, reply)) return;
    const alertId = decodeURIComponent(alertMatch[1]);
    if (!isUuid(alertId)) return reply(404, { error: "Alert not found" });
    const alert = await pool.query(
      "SELECT id FROM alerts WHERE id=$1 AND organization_id=$2",
      [alertId, user.organization_id],
    );
    if (!alert.rows[0]) return reply(404, { error: "Alert not found" });
    await pool.query(
      "INSERT INTO alert_receipts(alert_id,user_id) VALUES($1,$2) ON CONFLICT(alert_id,user_id) DO NOTHING",
      [alertId, user.id],
    );
    return reply(200, { alert: { id: alertId, acknowledged: true } });
  }

  return reply(404, { error: "Route not found" });
}

export const server = createServer((request, response) => {
  handleRequest(request, response).catch((error) => {
    console.error("Unhandled request failure", error);
    if (!response.headersSent) sendJson(response, 500, { error: "Internal server error" });
    else response.destroy();
  });
});

export async function startServer() {
  if (!process.env.DATABASE_URL) throw new Error("DATABASE_URL is required. In-memory mode is intentionally disabled.");
  await pool.query("SELECT 1");
  const migration = await pool.query("SELECT version FROM schema_migrations WHERE version = 1");
  if (!migration.rows[0]) throw new Error("Database schema is not migrated. Run npm run migrate before starting the API.");
  await new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(PORT, resolve);
  });
  const address = server.address();
  console.log(`Edu Ride backend listening on port ${typeof address === "object" && address ? address.port : PORT}`);
  return address;
}

export async function stopServer() {
  if (server.listening) await new Promise((resolve) => server.close(resolve));
  await pool.end();
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  startServer().catch((error) => {
    console.error(`Edu Ride backend failed to start: ${error.message}`);
    process.exit(1);
  });
}
