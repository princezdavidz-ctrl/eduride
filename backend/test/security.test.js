import test from "node:test";
import assert from "node:assert/strict";
import { createSessionToken, hashPassword, hashSessionToken, normalizeEmail, publicUser, verifyPassword } from "../security.js";

test("email normalization trims whitespace and lowercases", () => {
  assert.equal(normalizeEmail("  Parent@Example.COM "), "parent@example.com");
});

test("session tokens are random and stored as one-way hashes", () => {
  const first = createSessionToken();
  const second = createSessionToken();
  assert.notEqual(first, second);
  assert.notEqual(first, hashSessionToken(first));
  assert.equal(hashSessionToken(first), hashSessionToken(first));
  assert.equal(hashSessionToken(first).length, 64);
});

test("password hashes verify without storing the original password", async () => {
  const password = "Correct-Horse-Battery-42!";
  const hash = await hashPassword(password);
  assert.notEqual(hash, password);
  assert.equal(await verifyPassword(password, hash), true);
  assert.equal(await verifyPassword("wrong-password", hash), false);
});

test("public user projection excludes password hashes and internal fields", () => {
  const user = publicUser({
    id: "user-1",
    email: "parent@example.com",
    password_hash: "never-return-this",
    name: "Parent",
    phone: "",
    national_id: "",
    role: "parent",
    organization_id: null,
    verification_status: "pending",
  });
  assert.equal(user.email, "parent@example.com");
  assert.equal("password_hash" in user, false);
  assert.equal("password" in user, false);
});
