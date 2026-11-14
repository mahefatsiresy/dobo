// Shared by the edge functions: CORS for the web console (SPEC F16), JSON
// answers, and who is calling.
import { createClient } from "jsr:@supabase/supabase-js@2";

// The console signs in with a bearer token, never cookies, so any origin
// may call; the token is what grants anything.
export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export const reply = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

export const fail = (status: number, error: string) => reply(status, { error });

/// The answer to a browser's preflight, or null for any other request.
export const preflight = (req: Request): Response | null =>
  req.method === "OPTIONS"
    ? new Response(null, { status: 204, headers: corsHeaders })
    : null;

export const uuid =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
export const workerUsername = /^[a-z0-9._-]{3,30}$/;
export const email = /^[^@\s]+@[^@\s]+$/;
export const pin = /^\d{6}$/;
export const minPasswordLength = 8;
export const workerEmailDomain = "ouvriers.dobo.invalid";

export type Member = {
  id: string;
  association_id: string;
  is_admin: boolean;
  active: boolean;
};

/// The calling account's member row (`current_member`, under its own
/// rights), or null when signed out or without one.
export async function callerMember(req: Request): Promise<Member | null> {
  const caller = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    {
      global: {
        headers: { Authorization: req.headers.get("Authorization") ?? "" },
      },
      auth: { persistSession: false },
    },
  );
  const { data } = await caller.rpc("current_member");
  return data?.id ? data as Member : null;
}

/// A client with the service role: the admin API, no row-level security.
export const serviceClient = () =>
  createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );

export async function sha256Hex(text: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(text),
  );
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}
