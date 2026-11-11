import { createHash, randomBytes } from "node:crypto";
import bcrypt from "bcryptjs";

export function normalizeEmail(value) {
  return String(value ?? "").trim().toLowerCase();
}

export function hashSessionToken(token) {
  return createHash("sha256").update(token).digest("hex");
}

export function createSessionToken() {
  return randomBytes(32).toString("base64url");
}

export async function hashPassword(password) {
  return bcrypt.hash(password, 12);
}

export async function verifyPassword(password, passwordHash) {
  return bcrypt.compare(password, passwordHash);
}

export function publicUser(user) {
  return {
    id: user.id,
    email: user.email,
    name: user.name,
    phone: user.phone,
    nationalId: user.national_id ?? user.nationalId ?? "",
    role: user.role,
    organizationId: user.organization_id ?? user.organizationId ?? null,
    verificationStatus: user.verification_status ?? user.verificationStatus,
  };
}
