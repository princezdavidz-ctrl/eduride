import { randomBytes } from "node:crypto";
import pg from "pg";
import { hashSessionToken } from "../security.js";

const { Pool } = pg;
const action = process.argv[2] || "provision";
if (!["provision", "rotate", "revoke"].includes(action)) throw new Error("Usage: node scripts/provision-device.js [provision|rotate|revoke]");
const required = action === "provision" ? ["DATABASE_URL", "DEVICE_BUS_ID", "DEVICE_CODE", "DEVICE_VARIANT"] : ["DATABASE_URL", "DEVICE_CODE"];
for (const key of required) {
  if (!process.env[key]) throw new Error(`${key} is required to provision a vehicle device.`);
}
if (action === "provision" && !["vision_gps", "gps_only"].includes(process.env.DEVICE_VARIANT)) {
  throw new Error("DEVICE_VARIANT must be vision_gps or gps_only.");
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_SSL === "true" ? { rejectUnauthorized: true } : undefined,
  max: 1,
});
const client = await pool.connect();

try {
  await client.query("BEGIN");
  const existing = await client.query("SELECT id FROM devices WHERE device_code=$1 FOR UPDATE", [process.env.DEVICE_CODE]);
  if (action === "provision") {
    if (existing.rows[0]) throw new Error("DEVICE_CODE already exists; use rotate or revoke.");
    const bus = await client.query("SELECT id,organization_id FROM buses WHERE id=$1", [process.env.DEVICE_BUS_ID]);
    if (!bus.rows[0]) throw new Error("DEVICE_BUS_ID does not match a registered bus.");
    const token = randomBytes(32).toString("base64url");
    await client.query("INSERT INTO devices(organization_id,bus_id,device_code,token_hash,variant) VALUES($1,$2,$3,$4,$5)",
      [bus.rows[0].organization_id,bus.rows[0].id,process.env.DEVICE_CODE,hashSessionToken(token),process.env.DEVICE_VARIANT]);
    await client.query("COMMIT");
    process.stdout.write("Provisioned "+process.env.DEVICE_CODE+" ("+process.env.DEVICE_VARIANT+"). One-time token; store securely, never commit:\n"+token+"\n");
  } else {
    if (!existing.rows[0]) throw new Error("DEVICE_CODE does not exist.");
    if (action === "rotate") {
      const token = randomBytes(32).toString("base64url");
      await client.query("UPDATE devices SET token_hash=$1, active=true WHERE id=$2", [hashSessionToken(token),existing.rows[0].id]);
      await client.query("COMMIT");
      process.stdout.write("Rotated token for "+process.env.DEVICE_CODE+". Old token is now invalid. Store securely, never commit:\n"+token+"\n");
    } else {
      await client.query("UPDATE devices SET active=false WHERE id=$1", [existing.rows[0].id]);
      await client.query("COMMIT");
      process.stdout.write("Revoked device "+process.env.DEVICE_CODE+".\n");
    }
  }
} catch (error) {
  await client.query("ROLLBACK");
  throw error;
}
finally {
  client.release();
  await pool.end();
}
