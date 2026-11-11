import test from "node:test";
import assert from "node:assert/strict";
import pg from "pg";
import { hashPassword, hashSessionToken } from "../security.js";

const databaseUrl = process.env.TEST_DATABASE_URL;

test("persistent API enforces identity, organization and device boundaries", { skip: !databaseUrl }, async () => {
  process.env.DATABASE_URL = databaseUrl;
  process.env.PORT = "0";
  process.env.CORS_ORIGIN = "https://parent-app.example";
  const { Pool } = pg;
  const pool = new Pool({ connectionString: databaseUrl });
  const { startServer, stopServer } = await import("../server.js");
  let baseUrl;

  try {
    await pool.query("SELECT 1");
    const orgA = (await pool.query("INSERT INTO organizations(name) VALUES('Integration School A') RETURNING id")).rows[0].id;
    const orgB = (await pool.query("INSERT INTO organizations(name) VALUES('Integration School B') RETURNING id")).rows[0].id;
    const schoolA = (await pool.query("INSERT INTO schools(organization_id,name) VALUES($1,'Integration Academy A') RETURNING id",[orgA])).rows[0].id;
    const schoolB = (await pool.query("INSERT INTO schools(organization_id,name) VALUES($1,'Integration Academy B') RETURNING id",[orgB])).rows[0].id;
    const busA = (await pool.query("INSERT INTO buses(organization_id,school_id,fleet_number,status) VALUES($1,$2,'TEST-A','on_route') RETURNING id",[orgA,schoolA])).rows[0].id;
    const busAUnassigned = (await pool.query("INSERT INTO buses(organization_id,school_id,fleet_number) VALUES($1,$2,'TEST-A2') RETURNING id",[orgA,schoolA])).rows[0].id;
    const busB = (await pool.query("INSERT INTO buses(organization_id,school_id,fleet_number) VALUES($1,$2,'TEST-B') RETURNING id",[orgB,schoolB])).rows[0].id;
    const alertA = (await pool.query("INSERT INTO alerts(organization_id,bus_id,severity,title,message) VALUES($1,$2,'warning','Bus delay A','Traffic delay') RETURNING id",[orgA,busA])).rows[0].id;
    const alertB = (await pool.query("INSERT INTO alerts(organization_id,bus_id,severity,title,message) VALUES($1,$2,'info','Bus update B','Route update') RETURNING id",[orgB,busB])).rows[0].id;
    const adminHash = await hashPassword("Integration-Admin-Password-2026!");
    await pool.query(
      "INSERT INTO users(organization_id,email,password_hash,name,role,verification_status) VALUES($1,$2,$3,'Admin A','transport_admin','verified'),($4,$5,$3,'Admin B','transport_admin','verified')",
      [orgA,"admin-a@integration.test",adminHash,orgB,"admin-b@integration.test"],
    );
    const deviceToken = "integration-device-token-" + "x".repeat(40);
    await pool.query(
      "INSERT INTO devices(organization_id,bus_id,device_code,token_hash,variant) VALUES($1,$2,'INTEGRATION-DEVICE-A',$3,'gps_only')",
      [orgA,busA,hashSessionToken(deviceToken)],
    );

    const address = await startServer();
    baseUrl = `http://127.0.0.1:${address.port}`;

    const request = async (path, options = {}) => {
      const response = await fetch(baseUrl + path, {
        ...options,
        headers: { "content-type": "application/json", ...(options.headers || {}) },
      });
      const data = await response.json();
      return { status: response.status, data };
    };
    const signup = await request("/api/auth/signup", {
      method: "POST",
      body: JSON.stringify({ name: "Parent One", email: "parent-one@integration.test", password: "Parent-Integration-2026!" }),
    });
    assert.equal(signup.status, 201);
    const parentToken = signup.data.token;
    const storedParent = await pool.query("SELECT password_hash FROM users WHERE email='parent-one@integration.test'");
    assert.notEqual(storedParent.rows[0].password_hash, "Parent-Integration-2026!");

    const secondParent = await request("/api/auth/signup", {
      method: "POST",
      body: JSON.stringify({ name: "Parent Two", email: "parent-two@integration.test", password: "Parent-Integration-2026!" }),
    });
    assert.equal(secondParent.status, 201);

    const child = await request("/api/children", {
      method: "POST",
      headers: { authorization: `Bearer ${parentToken}` },
      body: JSON.stringify({ name: "Student One", school: "Integration Academy A" }),
    });
    assert.equal(child.status, 201);
    await pool.query("INSERT INTO child_bus_assignments(child_id,bus_id,school_id) VALUES($1,$2,$3)",[child.data.child.id,busA,schoolA]);

    await pool.query("INSERT INTO schools(organization_id,name) VALUES($1,'Integration Academy A')",[orgB]);
    const ambiguousSchool = await request("/api/children", {
      method: "POST",
      headers: { authorization: `Bearer ${parentToken}` },
      body: JSON.stringify({ name: "Student Two", school: "Integration Academy A" }),
    });
    assert.equal(ambiguousSchool.status, 409);

    const parentBTriesChild = await request(`/api/children/${child.data.child.id}`, {
      method: "PATCH",
      headers: { authorization: `Bearer ${secondParent.data.token}` },
      body: JSON.stringify({ school: "Integration Academy B" }),
    });
    assert.equal(parentBTriesChild.status, 404);

    const telemetryTime = new Date(Date.now() - 5_000).toISOString();
    const telemetry = await request("/api/device/telemetry", {
      method: "POST",
      headers: { "x-device-token": deviceToken },
      body: JSON.stringify({ latitude: -1.2864, longitude: 36.8172, speedKph: 24, heading: 180, recordedAt: telemetryTime }),
    });
    assert.equal(telemetry.status, 202);

    const imagePayload = await request("/api/device/telemetry", {
      method: "POST",
      headers: { "x-device-token": deviceToken },
      body: JSON.stringify({ latitude: -1.2, longitude: 36.8, image: "not-accepted" }),
    });
    assert.equal(imagePayload.status, 400);

    const missingCoordinates = await request("/api/device/telemetry", {
      method: "POST",
      headers: { "x-device-token": deviceToken },
      body: JSON.stringify({ longitude: 36.8 }),
    });
    assert.equal(missingCoordinates.status, 400);

    const parentBuses = await request("/api/buses", { headers: { authorization: `Bearer ${parentToken}` } });
    assert.equal(parentBuses.status, 200);
    assert.deepEqual(parentBuses.data.buses.map((bus) => bus.id), [busA]);
    assert.equal(parentBuses.data.buses[0].latitude, -1.2864);
    assert.equal(new Date(parentBuses.data.buses[0].updatedAt).toISOString(), telemetryTime);
    assert.equal(parentBuses.data.buses[0].locationFresh, true);

    const parentNotifications = await request("/api/notifications", { headers: { authorization: `Bearer ${parentToken}` } });
    assert.deepEqual(parentNotifications.data.notifications.map((alert) => alert.id), [alertA]);

    const parentAlerts = await request("/api/alerts", { headers: { authorization: `Bearer ${parentToken}` } });
    assert.equal(parentAlerts.status, 403);

    const adminA = await request("/api/auth/login", {
      method: "POST",
      body: JSON.stringify({ email: "admin-a@integration.test", password: "Integration-Admin-Password-2026!" }),
    });
    assert.equal(adminA.status, 200);
    const adminABuses = await request("/api/buses", { headers: { authorization: `Bearer ${adminA.data.token}` } });
    assert.equal(adminABuses.status, 200);
    assert.deepEqual(new Set(adminABuses.data.buses.map((bus) => bus.id)), new Set([busA,busAUnassigned]));
    const noGpsBus = adminABuses.data.buses.find((bus) => bus.id === busAUnassigned);
    assert.equal(noGpsBus.latitude, null);
    assert.equal(noGpsBus.longitude, null);
    assert.equal(noGpsBus.locationAvailable, false);
    assert.equal(noGpsBus.locationFresh, false);
    const adminAAlerts = await request("/api/alerts", { headers: { authorization: `Bearer ${adminA.data.token}` } });
    assert.deepEqual(adminAAlerts.data.data.map((alert) => alert.id), [alertA]);
    const acknowledged = await request(`/api/alerts/${alertA}`, {
      method: "PATCH",
      headers: { authorization: `Bearer ${adminA.data.token}` },
    });
    assert.equal(acknowledged.status, 200);

    const adminB = await request("/api/auth/login", {
      method: "POST",
      body: JSON.stringify({ email: "admin-b@integration.test", password: "Integration-Admin-Password-2026!" }),
    });
    const adminBBuses = await request("/api/buses", { headers: { authorization: `Bearer ${adminB.data.token}` } });
    assert.deepEqual(adminBBuses.data.buses.map((bus) => bus.id), [busB]);
    const adminBAlerts = await request("/api/alerts", { headers: { authorization: `Bearer ${adminB.data.token}` } });
    assert.deepEqual(adminBAlerts.data.data.map((alert) => alert.id), [alertB]);

    const resetUnavailable = await request("/api/auth/forgot-password", {
      method: "POST",
      body: JSON.stringify({ email: "parent-one@integration.test" }),
    });
    assert.equal(resetUnavailable.status, 200);
    assert.equal(resetUnavailable.data.available, false);

    const wrongPassword = await request("/api/auth/login", {
      method: "POST",
      body: JSON.stringify({ email: "admin-a@integration.test", password: "wrong-password" }),
    });
    assert.equal(wrongPassword.status, 401);

    const rejectedOrigin = await request("/health", { headers: { origin: "https://attacker.example" } });
    assert.equal(rejectedOrigin.status, 403);

    const invalidDevice = await request("/api/device/telemetry", {
      method: "POST",
      headers: { "x-device-token": "not-a-valid-device-token" },
      body: JSON.stringify({ latitude: 0, longitude: 0 }),
    });
    assert.equal(invalidDevice.status, 401);
  } finally {
    if (baseUrl) await stopServer();
    await pool.end();
  }
});
