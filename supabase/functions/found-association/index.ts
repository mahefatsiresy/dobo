// Founds the association from the web console (SPEC F16; M9 plan
// Decisions 1-3). No session needed: the founding code is the key. It is a
// secret (FOUNDING_CODE) and is spent by the first founding that uses it.
import {
  email as emailPattern,
  fail,
  minPasswordLength,
  preflight,
  reply,
  serviceClient,
  sha256Hex,
  uuid,
} from "../_shared/http.ts";

type Body = {
  code: string;
  email: string;
  password: string;
  founderName: string;
  associationName: string;
  groupName: string;
  siteName: string;
  locationNote?: string | null;
  associationId: string;
  groupId: string;
  siteId: string;
  memberId: string;
  personId: string;
  deviceId: string;
};

Deno.serve(async (req) => {
  const early = preflight(req);
  if (early) return early;
  if (req.method !== "POST") return fail(405, "method_not_allowed");

  let b: Body;
  try {
    b = await req.json();
  } catch {
    return fail(400, "bad_request");
  }
  const ids = [
    b.associationId,
    b.groupId,
    b.siteId,
    b.memberId,
    b.personId,
    b.deviceId,
  ];
  const names = [b.founderName, b.associationName, b.groupName, b.siteName];
  if (
    !ids.every((id) => uuid.test(id ?? "")) ||
    !names.every((n) => typeof n === "string" && n.trim() !== "")
  ) {
    return fail(400, "bad_request");
  }
  if (!emailPattern.test(b.email ?? "")) return fail(400, "bad_login");
  if ((b.password ?? "").length < minPasswordLength) {
    return fail(400, "bad_secret");
  }

  // A wrong, unset or spent code all get the same answer.
  const secret = Deno.env.get("FOUNDING_CODE") ?? "";
  const code = (b.code ?? "").trim();
  if (secret === "" || code !== secret) return fail(403, "bad_code");

  const admin = serviceClient();
  const email = b.email.toLowerCase();
  const { data: created, error: authError } = await admin.auth.admin
    .createUser({ email, password: b.password, email_confirm: true });
  if (authError || !created.user) {
    return authError?.code === "email_exists"
      ? fail(409, "login_taken")
      : fail(500, authError?.message ?? "auth_failed");
  }

  const note = b.locationNote?.trim();
  const { error } = await admin.rpc("found_association", {
    p_code_hash: await sha256Hex(code),
    p_user_id: created.user.id,
    p_email: email,
    p_association_id: b.associationId,
    p_association_name: b.associationName.trim(),
    p_group_id: b.groupId,
    p_group_name: b.groupName.trim(),
    p_site_id: b.siteId,
    p_site_name: b.siteName.trim(),
    p_location_note: note ? note : null,
    p_member_id: b.memberId,
    p_person_id: b.personId,
    p_member_name: b.founderName.trim(),
    p_locale: "fr",
    p_device_id: b.deviceId,
  });
  if (error) {
    // Nothing was founded: don't leave a login that can do nothing.
    await admin.auth.admin.deleteUser(created.user.id);
    // Spent before, or by a founding racing this one (primary key).
    if (error.message.includes("code_spent") || error.code === "23505") {
      return fail(403, "bad_code");
    }
    if (error.message.includes("association_exists")) {
      return fail(409, "association_exists");
    }
    return fail(500, error.message);
  }
  return reply(200, { memberId: b.memberId });
});
