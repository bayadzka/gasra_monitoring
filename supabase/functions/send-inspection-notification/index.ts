// supabase/functions/send-inspection-notification/index.ts

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient, SupabaseClient } from "npm:@supabase/supabase-js@2";
import { GoogleAuth } from "npm:google-auth-library@9";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const { record: newResult } = await req.json();

    // 1. Only proceed if the condition is 'tidak_baik'
    if (newResult.kondisi !== 'tidak_baik') {
      return new Response("ok: condition not 'tidak_baik'", { headers: corsHeaders });
    }

    const supabaseAdmin: SupabaseClient = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

    // 2. Check if a notification has already been sent for this inspection to avoid duplicates
    const { data: existingNotif } = await supabaseAdmin
      .from('inspections')
      .select('is_notified')
      .eq('id', newResult.inspection_id)
      .single();

    if (existingNotif?.is_notified) {
      return new Response("ok: notification already sent", { headers: corsHeaders });
    }

    // 3. Mark this inspection as notified to prevent future duplicates
    await supabaseAdmin
      .from('inspections')
      .update({ is_notified: true })
      .eq('id', newResult.inspection_id);

    // 4. Get FCM tokens for all admin_mobile users
    const { data: adminProfiles, error: adminError } = await supabaseAdmin
      .from("profiles")
      .select("fcm_token")
      .eq("role", "admin_mobile")
      .not("fcm_token", "is", null);

    if (adminError) throw new Error(`Failed to fetch admin tokens: ${adminError.message}`);
    
    const tokens = adminProfiles!.map((p) => p.fcm_token);
    if (tokens.length === 0) return new Response("ok", { headers: corsHeaders });

    // 5. Get details about the unit for the notification body
    const { data: inspectionData } = await supabaseAdmin.from('inspections').select('head_id, chassis_id, storage_id').eq('id', newResult.inspection_id).single();
    
    let unitCode = 'N/A';
    if (inspectionData?.head_id) {
        const { data } = await supabaseAdmin.from('heads').select('head_code').eq('id', inspectionData.head_id).single();
        if (data) unitCode = data.head_code;
    } else if (inspectionData?.chassis_id) {
        const { data } = await supabaseAdmin.from('chassis').select('chassis_code').eq('id', inspectionData.chassis_id).single();
        if (data) unitCode = data.chassis_code;
    } else if (inspectionData?.storage_id) {
        const { data } = await supabaseAdmin.from('storages').select('storage_code').eq('id', inspectionData.storage_id).single();
        if (data) unitCode = data.storage_code;
    }
    
    const { data: itemData } = await supabaseAdmin.from('inspection_items').select('name').eq('id', newResult.item_id).single();
    const itemName = itemData?.name ?? 'Item';

    // 6. Authenticate with Google and send the notification
    const auth = new GoogleAuth({
      credentials: { client_email: Deno.env.get("FIREBASE_CLIENT_EMAIL")!, private_key: Deno.env.get("FIREBASE_PRIVATE_KEY")!.replaceAll('\\n', '\n') },
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
            title: `🔧 Item Inspeksi Bermasalah`,
            body: `Unit ${unitCode}: ${itemName} ditandai 'Tidak Baik'.`,
          },
          data: {
            inspection_id: newResult.inspection_id.toString(),
            source_table: "inspection_results",
          },
        },
      };
      await fetch(fcmUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json", "Authorization": `Bearer ${accessToken}` },
        body: JSON.stringify(notificationPayload),
      });
    }

    return new Response(JSON.stringify({ message: "Notification sent" }), {
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