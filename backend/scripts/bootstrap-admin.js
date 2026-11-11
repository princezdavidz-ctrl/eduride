import pg from "pg";
import { hashPassword, normalizeEmail } from "../security.js";

const { Pool } = pg;
const required = ["DATABASE_URL", "BOOTSTRAP_ADMIN_EMAIL", "BOOTSTRAP_ADMIN_PASSWORD", "BOOTSTRAP_ADMIN_NAME", "BOOTSTRAP_ORGANIZATION_NAME"];
for (const key of required) {
  if (!process.env[key]) throw new Error(`${key} is required to bootstrap the first transport administrator.`);
}
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_SSL === "true" ? { rejectUnauthorized: true } : undefined,
  max: 1,
});

try {
  const email = normalizeEmail(process.env.BOOTSTRAP_ADMIN_EMAIL);
  const passwordHash = await hashPassword(process.env.BOOTSTRAP_ADMIN_PASSWORD);
  await pool.query("BEGIN");
  const organization = await pool.query(
    "INSERT INTO organizations(name) VALUES($1) RETURNING id",
    [process.env.BOOTSTRAP_ORGANIZATION_NAME.trim()],
  );
  await pool.query(
    "INSERT INTO users(organization_id,email,password_hash,name,role,verification_status) VALUES($1,$2,$3,$4,'transport_admin','verified')",
    [organization.rows[0].id, email, passwordHash, process.env.BOOTSTRAP_ADMIN_NAME.trim()],
  );
  await pool.query("COMMIT");
  process.stdout.write("Initial transport administrator created. Remove bootstrap credentials from the environment now.\n");
} catch (error) {
  await pool.query("ROLLBACK").catch(() => {});
  process.stderr.write(`Admin bootstrap failed: ${error.message}\n`);
  process.exitCode = 1;
} finally {
  await pool.end();
}
