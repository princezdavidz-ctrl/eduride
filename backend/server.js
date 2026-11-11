import { createServer } from "node:http";
import { randomUUID } from "node:crypto";

const PORT = Number(process.env.PORT || 8787);
const APP_BASE_PATH = (process.env.APP_BASE_PATH || "").replace(/\/+$/, "");
const SESSION_TTL_MS = 1000 * 60 * 60 * 8;
const sessions = new Map();
const users = new Map();
const children = new Map();
const preferences = new Map();

users.set("admin@tread.local", {
  id: "user-admin",
  email: "admin@tread.local",
  password: "TREAD-demo-2026",
  name: "Amina Mwangi",
  phone: "+254 700 000 000",
  nationalId: "DEMO-001",
  role: "transport_admin",
  organization: "TREAD Demo School Network",
  verificationStatus: "verified",
});

const schools = [];
const buses = [];
const routes = [];
const journeys = [];
const alerts = [];

function sendJson(response, status, payload) {
  response.writeHead(status, {
    "content-type": "application/json; charset=utf-8",
    "access-control-allow-origin": process.env.CORS_ORIGIN || "*",
    "access-control-allow-headers": "content-type, authorization",
    "access-control-allow-methods": "GET, POST, PATCH, OPTIONS",
  });
  response.end(JSON.stringify(payload));
}

function readBody(request) {
  return new Promise((resolve, reject) => {
    let body = "";
    request.on("data", (chunk) => {
      body += chunk;
      if (body.length > 10_000) reject(new Error("Request body too large"));
    });
    request.on("end", () => {
      try { resolve(body ? JSON.parse(body) : {}); } catch { reject(new Error("Invalid JSON request")); }
    });
    request.on("error", reject);
  });
}

function authenticatedUser(request) {
  const token = request.headers.authorization?.replace(/^Bearer\s+/i, "");
  const session = token ? sessions.get(token) : undefined;
  if (!session) return undefined;
  if (Date.now() - session.createdAt > SESSION_TTL_MS) {
    sessions.delete(token);
    return undefined;
  }
  return [...users.values()].find((user) => user.id === session.userId);
}

function requireUser(request, response) {
  const user = authenticatedUser(request);
  if (!user) sendJson(response, 401, { error: "Authentication required" });
  return user;
}

function publicUser(user) {
  const { password, ...safeUser } = user;
  return safeUser;
}

function collectionFor(pathname) {
  if (pathname === "/api/schools") return schools;
  if (pathname === "/api/routes") return routes;
  if (pathname === "/api/alerts") return alerts;
  if (pathname === "/api/journeys") return journeys;
  if (pathname === "/api/children") return [...children.values()].filter((child) => child.parentId);
  return undefined;
}

const server = createServer(async (request, response) => {
  if (request.method === "OPTIONS") return sendJson(response, 200, {});
  const url = new URL(request.url, `http://${request.headers.host}`);
  const pathname =
    APP_BASE_PATH && (url.pathname === APP_BASE_PATH || url.pathname.startsWith(`${APP_BASE_PATH}/`))
      ? url.pathname.slice(APP_BASE_PATH.length) || "/"
      : url.pathname;

  if (request.method === "GET" && pathname === "/health") return sendJson(response, 200, { ok: true, service: "tread-backend" });

  if (request.method === "POST" && pathname === "/api/auth/forgot-password") {
    return sendJson(response, 200, {
      available: false,
      message: "Password reset is not configured. Please contact support.",
    });
  }

  if (request.method === "POST" && pathname === "/api/auth/login") {
    try {
      const { email, password } = await readBody(request);
      const user = users.get(String(email || "").toLowerCase());
      if (!user || user.password !== password) return sendJson(response, 401, { error: "Invalid email or password" });
      const token = randomUUID();
      sessions.set(token, { token, userId: user.id, createdAt: Date.now() });
      return sendJson(response, 200, { token, user: publicUser(user) });
    } catch (error) { return sendJson(response, 400, { error: error.message }); }
  }

  if (request.method === "POST" && pathname === "/api/auth/signup") {
    try {
      const body = await readBody(request);
      const email = String(body.email || "").toLowerCase();
      if (!email || !String(body.password || "").trim() || !String(body.name || "").trim()) return sendJson(response, 400, { error: "Name, email, and password are required" });
      if (users.has(email)) return sendJson(response, 409, { error: "An account with this email already exists" });
      const user = { id: randomUUID(), email, password: String(body.password), name: String(body.name), phone: "", nationalId: "", role: "parent", organization: "", verificationStatus: "pending" };
      users.set(email, user);
      const token = randomUUID();
      sessions.set(token, { token, userId: user.id, createdAt: Date.now() });
      return sendJson(response, 200, { token, user: publicUser(user) });
    } catch (error) { return sendJson(response, 400, { error: error.message }); }
  }

  if (request.method === "GET" && pathname === "/api/auth/me") {
    const user = authenticatedUser(request);
    return user ? sendJson(response, 200, { user: publicUser(user) }) : sendJson(response, 401, { error: "Authentication required" });
  }

  if (request.method === "POST" && pathname === "/api/auth/logout") {
    const token = request.headers.authorization?.replace(/^Bearer\s+/i, "");
    if (token) sessions.delete(token);
    return sendJson(response, 200, { ok: true });
  }

  const user = requireUser(request, response);
  if (!user) return;

  if (request.method === "GET" && pathname === "/api/buses") {
    const now = new Date().toISOString();
    return sendJson(response, 200, { buses: buses.map((bus) => ({ ...bus, updatedAt: now })) });
  }

  if (request.method === "GET" && pathname === "/api/profile") return sendJson(response, 200, { profile: publicUser(user) });

  if (request.method === "PATCH" && pathname === "/api/profile") {
    try {
      const body = await readBody(request);
      for (const field of ["name", "phone", "nationalId"]) if (body[field] !== undefined) user[field] = String(body[field]);
      return sendJson(response, 200, { profile: publicUser(user) });
    } catch (error) { return sendJson(response, 400, { error: error.message }); }
  }

  if (request.method === "GET" && pathname === "/api/children") {
    return sendJson(response, 200, { children: [...children.values()].filter((child) => child.parentId === user.id) });
  }

  if (request.method === "POST" && pathname === "/api/children") {
    try {
      const body = await readBody(request);
      if (!String(body.name || "").trim() || !String(body.school || "").trim()) return sendJson(response, 400, { error: "Child name and school are required" });
      const child = { id: randomUUID(), parentId: user.id, name: String(body.name).trim(), school: String(body.school).trim(), verificationStatus: "pending" };
      children.set(child.id, child);
      return sendJson(response, 200, { child });
    } catch (error) { return sendJson(response, 400, { error: error.message }); }
  }

  const childMatch = pathname.match(/^\/api\/children\/([^/]+)$/);
  if (request.method === "PATCH" && childMatch) {
    try {
      const childId = decodeURIComponent(childMatch[1]);
      const child = children.get(childId);
      if (!child || child.parentId !== user.id) {
        return sendJson(response, 404, { error: "Child not found" });
      }

      const body = await readBody(request);
      const school = String(body.school || "").trim();
      if (!school) return sendJson(response, 400, { error: "School is required" });

      child.school = school;
      child.verificationStatus = "pending";
      return sendJson(response, 200, { child });
    } catch (error) { return sendJson(response, 400, { error: error.message }); }
  }

  if (request.method === "POST" && pathname === "/api/verification") {
    user.verificationStatus = "pending";
    return sendJson(response, 200, { status: user.verificationStatus, message: "Your profile is waiting for school verification" });
  }

  if (request.method === "GET" && pathname === "/api/verification") return sendJson(response, 200, { status: user.verificationStatus });

  if (request.method === "GET" && pathname === "/api/notifications") {
    return sendJson(response, 200, { notifications: alerts.map((alert) => ({ ...alert, read: alert.acknowledged })) });
  }

  if (request.method === "GET" && pathname === "/api/preferences") return sendJson(response, 200, { preferences: preferences.get(user.id) || { language: "English", tripUpdates: true, arrivalAlerts: true } });

  if (request.method === "PATCH" && pathname === "/api/preferences") {
    try { const body = await readBody(request); const next = { ...(preferences.get(user.id) || {}), ...body }; preferences.set(user.id, next); return sendJson(response, 200, { preferences: next }); } catch (error) { return sendJson(response, 400, { error: error.message }); }
  }

  const collection = collectionFor(pathname);
  if (request.method === "GET" && collection) return sendJson(response, 200, { data: collection });

  if (request.method === "PATCH" && pathname.startsWith("/api/alerts/")) {
    const alert = alerts.find((item) => item.id === pathname.split("/").pop());
    if (!alert) return sendJson(response, 404, { error: "Alert not found" });
    alert.acknowledged = true;
    return sendJson(response, 200, { alert });
  }

  return sendJson(response, 404, { error: "Route not found" });
});

server.listen(PORT, () => console.log(`TREAD backend listening on http://localhost:${PORT}`));
