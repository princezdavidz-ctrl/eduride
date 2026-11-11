import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import pg from "pg";

const { Pool } = pg;
const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) throw new Error("DATABASE_URL is required to run backend migrations.");

const pool = new Pool({
  connectionString: databaseUrl,
  ssl: process.env.DATABASE_SSL === "true" ? { rejectUnauthorized: true } : undefined,
  max: 2,
});

const client = await pool.connect();
try {
  const schemaPath = join(dirname(fileURLToPath(import.meta.url)), "db", "schema.sql");
  const schema = await readFile(schemaPath, "utf8");
  await client.query("BEGIN");
  await client.query(schema);
  await client.query("INSERT INTO schema_migrations(version) VALUES (1) ON CONFLICT (version) DO NOTHING");
  await client.query("COMMIT");
  process.stdout.write("Edu Ride database schema is ready (version 1).\n");
} catch (error) {
  await client.query("ROLLBACK").catch(() => {});
  process.stderr.write(`Database migration failed: ${error.message}\n`);
  process.exitCode = 1;
} finally {
  client.release();
  await pool.end();
}
