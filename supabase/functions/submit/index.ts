// deno-lint-ignore-file no-explicit-any
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
type Json = Record<string, unknown>;

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });

  try {
    const body = await req.json() as {
      type?: "HR" | "PROCUREMENT" | "SERVICE";
      orgId: string;
      deptId?: string | null;
      projectId?: string | null;
      formData: Json;
      attachments?: { name: string; url?: string }[];
    };

    // Use the caller's JWT so RLS applies
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: req.headers.get("Authorization")! } } }
    );

    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return Response.json({ ok:false, error:"Unauthorized" }, { status:401 });

    // 1) Insert the request (RLS-friendly)
    const { data: reqRow, error: insErr } = await supabase
      .from("requests")
      .insert([{
        type: body.type ?? "HR",
        org_id: body.orgId,
        dept_id: body.deptId ?? null,
        project_id: body.projectId ?? null,
        payload: body.formData ?? {},
        status: "submitted",
        created_by: user.id,
      }])
      .select()
      .single();
    if (insErr) return Response.json({ ok:false, error:insErr.message }, { status:400 });

    // 2) Relay to Apps Script (kept secret in function env)
    const appsUrl   = Deno.env.get("APPSCRIPT_BASE_URL")!;
    const appsToken = Deno.env.get("APPSCRIPT_TOKEN")!;
    const relay = await fetch(appsUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        token: appsToken,
        requestId: reqRow.id,
        type: reqRow.type,
        orgId: reqRow.org_id,
        deptId: reqRow.dept_id,
        projectId: reqRow.project_id,
        formData: body.formData ?? {},
        attachments: body.attachments ?? []
      }),
    }).catch(e => ({ ok:false, statusText:String(e) } as Response));

    let webhook: Json | null = null;
    try { webhook = (relay as any).ok ? await (relay as any).json() : { status:"error" }; } catch {}

    await supabase.from("requests")
      .update({ apps_script_job_id: (webhook as any)?.jobId ?? null })
      .eq("id", reqRow.id);

    // 3) Optional demo: always approve
    if (Deno.env.get("AUTO_APPROVE") === "true") {
      const admin = createClient(
        Deno.env.get("SUPABASE_URL")!,
        Deno.env.get("SERVICE_ROLE_KEY")!
      );
      await admin.from("approvals").insert([{
        request_id: reqRow.id,
        approver_id: user.id,
        decision: "approved",
        comment: "Auto-approved (demo)",
        decided_at: new Date().toISOString(),
      }]);
      await admin.from("requests").update({ status:"approved" }).eq("id", reqRow.id);
    }

    return Response.json({ ok:true, id:reqRow.id, webhook });
  } catch (e: any) {
    return Response.json({ ok:false, error:String(e?.message ?? e) }, { status:500 });
  }
});
