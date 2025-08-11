// supabase/functions/send-notification/index.ts

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient, SupabaseClient } from "npm:@supabase/supabase-js@2";
import { GoogleAuth } from "npm:google-auth-library@9";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { record: newReport } = await req.json();

    const supabaseAdmin: SupabaseClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const { data: adminProfiles, error: adminError } = await supabaseAdmin
      .from("profiles")
      .select("fcm_token")
      .eq("role", "admin_mobile")
      .not("fcm_token", "is", null);

    if (adminError) throw new Error(`Failed to fetch admin tokens: ${adminError.message}`);
    
    const tokens = adminProfiles!.map((p) => p.fcm_token);
    if (tokens.length === 0) {
      return new Response("ok", { headers: corsHeaders });
    }

    let unitCode = 'N/A';
    if (newReport.head_id) {
        const { data } = await supabaseAdmin.from('heads').select('head_code').eq('id', newReport.head_id).single();
        if (data) unitCode = data.head_code;
    } else if (newReport.chassis_id) {
        const { data } = await supabaseAdmin.from('chassis').select('chassis_code').eq('id', newReport.chassis_id).single();
        if (data) unitCode = data.chassis_code;
    } else if (newReport.storage_id) {
        const { data } = await supabaseAdmin.from('storages').select('storage_code').eq('id', newReport.storage_id).single();
        if (data) unitCode = data.storage_code;
    }
    
    // [FIX] Memperbaiki format private key
    const privateKey = Deno.env.get("FIREBASE_PRIVATE_KEY")!.replaceAll('\\n', '\n');

    const auth = new GoogleAuth({
      credentials: {
        client_email: Deno.env.get("FIREBASE_CLIENT_EMAIL")!,
        private_key: privateKey, // Menggunakan key yang sudah diformat
      },
      scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
    });
    const accessToken = await auth.getAccessToken();

    const projectId = Deno.env.get("FIREBASE_PROJECT_ID");
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

    for (const token of tokens) {
      const notificationPayload = {
        message: {
          token: token,
          notification: {
            title: `🚨 Laporan Masalah Baru: ${newReport.custom_title}`,
            body: `Unit ${unitCode} membutuhkan perhatian. Klik untuk melihat detail.`,
          },
          data: {
            report_id: newReport.id.toString(),
            source_table: "problem_reports",
          },
        },
      };
      await fetch(fcmUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json", "Authorization": `Bearer ${accessToken}` },
        body: JSON.stringify(notificationPayload),
      });
    }

    return new Response(JSON.stringify({ message: "Notifications sent" }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    console.error("An error occurred:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});