// An admin sets a new password (member) or PIN (worker) for an account of
// their association (SPEC F14, F16; M9 plan Decision 9). Sessions already
// open are not revoked: a lost phone is handled by deactivating it.
import {
  callerMember,
  fail,
  minPasswordLength,
  pin,
  preflight,
  reply,
  serviceClient,
  uuid,
} from "../_shared/http.ts";

Deno.serve(async (req) => {
  const early = preflight(req);
  if (early) return early;
  if (req.method !== "POST") return fail(405, "method_not_allowed");

  const me = await callerMember(req);
  if (!me || !me.is_admin || !me.active) return fail(403, "not_admin");

  let b: { memberId: string; secret: string };
  try {
    b = await req.json();
  } catch {
    return fail(400, "bad_request");
  }
  if (!uuid.test(b.memberId ?? "")) return fail(400, "bad_request");

  const admin = serviceClient();
  const { data: target } = await admin
    .from("members")
    .select("role, user_id")
    .eq("id", b.memberId)
    .eq("association_id", me.association_id)
    .maybeSingle();
  if (!target?.user_id) return fail(404, "no_member");

  const secret = b.secret ?? "";
  const ok = target.role === "worker"
    ? pin.test(secret)
    : secret.length >= minPasswordLength;
  if (!ok) return fail(400, "bad_secret");

  const { error } = await admin.auth.admin.updateUserById(target.user_id, {
    password: secret,
  });
  if (error) return fail(500, error.message);
  return reply(200, {});
});
