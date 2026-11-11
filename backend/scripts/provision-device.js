import { randomBytes } from "node:crypto";
import pg from "pg";
import { hashSessionToken } from "../security.js";

const { Pool } = pg;
const required = ["DATABASE_URL", "DEVICE_BUS_ID", "DEVICE_CODE", "DEVICE_VARIANT"];
for (const key of required) {
  if (!process.env[key]) throw new Error(`${key} is required to provision a vehicle device.`);
}
if (!["vision_gps", "gps_only"].includes(process.env.DEVICE_VARIANT)) {
  throw new Error("DEVICE_VARIANT must be vision_gps or gps_only.");
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_SSL === "true" ? { rejectUnauthorized: true } : undefined,
  max: 1,
});
const client = await pool.connect();

try {
  const bus = await client.query("SELECT id,organization_id FROM buses WHERE id=$1", [process.env.DEVICE_BUS_ID]);
  if (!bus.rows[0]) throw new Error("DEVICE_BUS_ID does not match a registered bus.");
  const token = randomBytes(32).toString("base64url");
  await client.query(
    "INSERT INTO devices(organization_id,bus_id,device_code,token_hash,variant) VALUES($1,$2,$3,$4,$5)",
    [bus.rows[0].organization_id,bus.rows[0].id,process.env.DEVICE_CODE,hashSessionToken(token),process.env.DEVICE_VARIANT],
  );
  process.stdout.write(`Device provisioned. Store this token securely on the device; it will not be shown again:\n${token}\n`);
} finally {
  client.release();
  await pool.end();
}
