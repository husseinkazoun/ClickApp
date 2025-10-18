// supabase/functions/submit/index.ts
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type Json = Record<string, unknown>;

function withCorsHeaders(resp: Response, extra?: HeadersInit): Response {
  const headers = new Headers(resp.headers);
  headers.set("Access-Control-Allow-Origin", "*");
  headers.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  headers.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
  if (extra) new Headers(extra).forEach((v, k) => headers.set(k, v));
  return new Response(resp.body, {
    status: resp.status,
    statusText: resp.statusText,
    headers,
  });
}

function json(data: unknown, status = 200) {
  return withCorsHeaders(
    new Response(JSON.stringify(data), {
      status,
      headers: { "Content-Type": "application/json" },
    })
  );
}

Deno.serve(async (req) => {
  // Preflight
  if (req.method === "OPTIONS") {
    return withCorsHeaders(new Response(null, { status: 204 }));
  }
  if (req.method !== "POST") {
    return withCorsHeaders(new Response("Method not allowed", { status: 405 }));
  }

  try {
    // ---- Auth: require Authorization so RLS applies
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return json({ ok: false, error: "Missing Authorization header" }, 401);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const supabase = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user },
      error: userErr,
    } = await supabase.auth.getUser();
    if (userErr || !user) {
      return json({ ok: false, error: "Unauthenticated" }, 401);
    }

    // ---- Parse body
    const body = (await req.json()) as {
      type?: "HR" | "PROCUREMENT" | "SERVICE" | "Recruitment";
      orgId: string;
      deptId?: string | null;
      projectId?: string | null;
      formData: Json;
      attachments?: { name: string; url?: string }[];
    };

    if (!body?.type || !body?.orgId || !body?.formData) {
      return json({ ok: false, error: "Missing required fields" }, 400);
    }

    // ---- 1) Create request row
    const { data: reqRow, error: insertErr } = await supabase
      .from("requests")
      .insert([
        {
          type: body.type,
          org_id: body.orgId,
          dept_id: body.deptId ?? null,
          project_id: body.projectId ?? null,
          payload: body.formData,
          status: "submitted",
        },
      ])
      .select()
      .single();

    if (insertErr || !reqRow) {
      console.error("Insert error:", insertErr);
      return json({ ok: false, error: "DB insert failed" }, 400);
    }

    // ---- 2) Relay to Apps Script (server-side secret)
    const appsUrl = Deno.env.get("APPSCRIPT_BASE_URL")!;
    const appsToken = Deno.env.get("APPSCRIPT_TOKEN")!;
    let webhook: Json | null = null;

    try {
      const relay = await fetch(appsUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          token: appsToken,
          requestId: reqRow.id,
          type: reqRow.type,
          orgId: body.orgId,
          deptId: body.deptId ?? null,
          projectId: body.projectId ?? null,
          formData: body.formData,
          attachments: body.attachments ?? [],
        }),
      });

      if (relay.ok) {
        try {
          webhook = await relay.json();
        } catch {
          // if Apps Script returned non-JSON, capture text
          const t = await relay.text();
          webhook = { status: "ok", body: t };
        }
      } else {
        const t = await relay.text().catch(() => "");
        console.error("Apps Script relay failed:", relay.status, t);
        webhook = { status: "error", httpStatus: relay.status, body: t };
      }
    } catch (e) {
      console.error("Apps Script fetch threw:", e);
      webhook = { status: "error", message: String(e) };
    }

    const { error: updateErr } = await supabase
      .from("requests")
      .update({ apps_script_job_id: (webhook as any)?.jobId ?? null })
      .eq("id", reqRow.id);

    if (updateErr) {
      console.error("Failed to update requests with jobId:", updateErr);
      return json(
        { ok: false, error: "Failed to store webhook result", webhook },
        500
      );
    }

    // ---- 3) Optional demo: auto-approve only if not production
    const env = (Deno.env.get("ENV") || "staging").toLowerCase();
    const autoApprove =
      Deno.env.get("AUTO_APPROVE") === "true" && env !== "production";

    if (autoApprove) {
      const serviceRoleKey = Deno.env.get("SERVICE_ROLE_KEY")!;
      const admin = createClient(supabaseUrl, serviceRoleKey, {
        auth: { persistSession: false },
      });

      const { error: insApprovalErr } = await admin.from("approvals").insert([
        {
          request_id: reqRow.id,
          approver_id: user.id,
          decision: "approved",
          comment: "Auto-approved (demo)",
          decided_at: new Date().toISOString(),
        },
      ]);
      if (insApprovalErr) {
        console.error("Auto-approve insert failed:", insApprovalErr);
      }

      const { error: setStatusErr } = await admin
        .from("requests")
        .update({ status: "approved" })
        .eq("id", reqRow.id);
      if (setStatusErr) {
        console.error("Auto-approve status update failed:", setStatusErr);
      }
    }

    return json({ ok: true, id: reqRow.id, webhook, autoApproved: autoApprove });
  } catch (e) {
    console.error("Unhandled submit error:", e);
    return json({ ok: false, error: "Internal error" }, 500);
  }
});

