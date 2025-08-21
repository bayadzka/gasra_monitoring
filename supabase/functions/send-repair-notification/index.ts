// supabase/functions/send-repair-notification/index.ts

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient, SupabaseClient } from "npm:@supabase/supabase-js@2";
import { GoogleAuth } from "npm:google-auth-library@9";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// [DIUBAH] Tipe data disesuaikan untuk menerima array
type ProblemReport = {
  reported_by_id: string;
  custom_title: string;
};

type InspectionResult = {
  inspections: { inspector_id: string }[] | null; // Menerima array objek
  inspection_items: { name: string }[] | null;   // Menerima array objek
};


serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { record: newRepair } = await req.json();

    const supabaseAdmin: SupabaseClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    let reporterId: string | null = null;
    let itemName: string | null = 'Masalah';
    
    if (newRepair.problem_report_id) {
      const { data, error } = await supabaseAdmin.from('problem_reports').select('reported_by_id, custom_title').eq('id', newRepair.problem_report_id).single();
      if (error) throw new Error(error.message);
      
      const reportData = data as ProblemReport | null;
      if (reportData) {
        reporterId = reportData.reported_by_id;
        itemName = reportData.custom_title;
      }

    } else if (newRepair.inspection_result_id) {
      const { data, error } = await supabaseAdmin.from('inspection_results').select('inspections(inspector_id), inspection_items(name)').eq('id', newRepair.inspection_result_id).single();
      if (error) throw new Error(error.message);

      const inspectionData = data as InspectionResult | null;
      if (inspectionData) {
        // [FIX] Mengambil data dari elemen pertama array
        reporterId = inspectionData.inspections?.[0]?.inspector_id ?? null;
        itemName = inspectionData.inspection_items?.[0]?.name ?? 'Item';
      }
    }

    if (!reporterId) {
      return new Response("ok: Reporter not found", { headers: corsHeaders });
    }

    const { data: reporterProfile, error: profileError } = await supabaseAdmin
      .from("profiles")
      .select("fcm_token")
      .eq("id", reporterId)
      .single();

    if (profileError || !reporterProfile?.fcm_token) {
      return new Response("ok: Reporter FCM token not found", { headers: corsHeaders });
    }
    
    const token = reporterProfile.fcm_token;
    const { data: repairedByProfile } = await supabaseAdmin.from('profiles').select('name').eq('id', newRepair.repaired_by_id).single();
    const repairedByName = repairedByProfile?.name ?? 'Teknisi';

    const auth = new GoogleAuth({
      credentials: { client_email: Deno.env.get("FIREBASE_CLIENT_EMAIL")!, private_key: Deno.env.get("FIREBASE_PRIVATE_KEY")!.replaceAll('\\n', '\n') },
      scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
    });
    const accessToken = await auth.getAccessToken();

    const projectId = Deno.env.get("FIREBASE_PROJECT_ID");
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

    const notificationPayload = {
      message: {
        token: token,
        notification: {
          title: `✅ Laporan Selesai Diperbaiki`,
          body: `Masalah "${itemName}" telah diperbaiki oleh ${repairedByName}.`,
        },
        data: {
          maintenance_id: newRepair.id.toString(),
          source_table: "maintenance_records",
        },
      },
    };

    await fetch(fcmUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json", "Authorization": `Bearer ${accessToken}` },
      body: JSON.stringify(notificationPayload),
    });

    return new Response(JSON.stringify({ message: "Notifikasi perbaikan terkirim" }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});