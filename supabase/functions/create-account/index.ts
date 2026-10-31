// Creates a member's or a worker's account (SPEC F14; plan Decision 3).
// Only an active admin may call it. The account is confirmed at once, so no
// email is ever sent; the admin passes the password or PIN on in person.
import { createClient } from "jsr:@supabase/supabase-js@2";

const workerEmailDomain = "ouvriers.dobo.invalid";
const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const username = /^[a-z0-9._-]{3,30}$/;

type Body = {
  memberId: string;
  name: string;
  role: "member" | "worker";
  login: string;
  secret: string;
  groupId?: string | null;
  personId?: string | null;
  isAdmin: boolean;
  isSales: boolean;
  locale: string;
  deviceId: string;
};

const reply = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

const fail = (status: number, error: string) => reply(status, { error });

Deno.serve(async (req) => {
  if (req.method !== "POST") return fail(405, "method_not_allowed");

  const url = Deno.env.get("SUPABASE_URL")!;
  const caller = createClient(url, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
    auth: { persistSession: false },
  });
  const { data: me } = await caller.rpc("current_member");
  if (!me?.id || !me.is_admin) return fail(403, "not_admin");

  let b: Body;
  try {
    b = await req.json();
  } catch {
    return fail(400, "bad_request");
  }
  const okIds = uuid.test(b.memberId ?? "") && uuid.test(b.deviceId ?? "") &&
    [b.groupId, b.personId].every((id) => id == null || uuid.test(id));
  if (
    !okIds || !b.name?.trim() || !["member", "worker"].includes(b.role) ||
    !["fr", "mg"].includes(b.locale)
  ) {
    return fail(400, "bad_request");
  }

  let email: string;
  if (b.role === "worker") {
    if (!username.test(b.login ?? "")) return fail(400, "bad_login");
    if (!/^\d{6}$/.test(b.secret ?? "")) return fail(400, "bad_secret");
    email = `${b.login}@${workerEmailDomain}`;
  } else {
    if (!/^[^@\s]+@[^@\s]+$/.test(b.login ?? "")) return fail(400, "bad_login");
    if ((b.secret ?? "").length < 8) return fail(400, "bad_secret");
    email = b.login.toLowerCase();
  }

  const admin = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
    auth: { persistSession: false },
  });
  const { data: created, error: authError } = await admin.auth.admin.createUser({
    email,
    password: b.secret,
    email_confirm: true,
  });
  if (authError || !created.user) {
    return authError?.code === "email_exists"
      ? fail(409, "login_taken")
      : fail(500, authError?.message ?? "auth_failed");
  }

  const now = new Date().toISOString();
  const { data: row, error } = await admin.from("members").insert({
    id: b.memberId,
    association_id: me.association_id,
    entered_by: me.id,
    created_at_device: now,
    device_id: b.deviceId,
    updated_at_device: now,
    name: b.name.trim(),
    group_id: b.groupId ?? null,
    person_id: b.personId ?? null,
    role: b.role,
    is_admin: b.isAdmin,
    is_sales: b.isSales,
    active: true,
    locale: b.locale,
    login: b.role === "worker" ? b.login : email,
    user_id: created.user.id,
  }).select().single();
  if (error) {
    // No member row: don't leave an account that can do nothing.
    await admin.auth.admin.deleteUser(created.user.id);
    return fail(500, error.message);
  }
  return reply(200, row);
});
