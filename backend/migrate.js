import { readdir, readFile } from "node:fs/promises";
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
  await client.query(`CREATE TABLE IF NOT EXISTS schema_migrations (
    version integer PRIMARY KEY,
    applied_at timestamptz NOT NULL DEFAULT now()
  )`);
  const migrationsPath = join(dirname(fileURLToPath(import.meta.url)), "db", "migrations");
  const files = (await readdir(migrationsPath)).filter((file) => /^\d+_.+\.sql$/.test(file)).sort();
  for (const file of files) {
    const version = Number(file.split("_", 1)[0]);
    const existing = await client.query("SELECT 1 FROM schema_migrations WHERE version=$1", [version]);
    if (existing.rows[0]) continue;
    const sql = await readFile(join(migrationsPath, file), "utf8");
    await client.query("BEGIN");
    try {
      await client.query(sql);
      await client.query("INSERT INTO schema_migrations(version) VALUES($1)", [version]);
      await client.query("COMMIT");
      process.stdout.write(`Applied database migration ${file}.\n`);
    } catch (error) {
      await client.query("ROLLBACK");
      throw error;
    }
  }
  process.stdout.write("Edu Ride database migrations are up to date.\n");
} catch (error) {
  process.stderr.write(`Database migration failed: ${error.message}\n`);
  process.exitCode = 1;
} finally {
  client.release();
  await pool.end();
}
