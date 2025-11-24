// supabase/functions/whatsapp-webhook/index.ts
// @ts-ignore - Deno runtime
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
// @ts-ignore - Deno runtime
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// @ts-ignore - Deno global object
// Las Edge Functions de Supabase tienen estas variables automáticamente disponibles
const supabaseUrl = Deno.env.get("SUPABASE_URL") || Deno.env.get("PROJECT_URL") || "";
// @ts-ignore - Deno global object
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || Deno.env.get("SERVICE_ROLE_KEY") || "";

serve(async (req: Request) => {
  const url = new URL(req.url);

  // --- VERIFICACIÓN DE WEBHOOK DE META (OBLIGATORIO) ---
  const mode = url.searchParams.get("hub.mode");
  const token = url.searchParams.get("hub.verify_token");
  const challenge = url.searchParams.get("hub.challenge");

  if (mode === "subscribe" && token === "mi_token_secreto_123") {
    console.log("✅ Webhook verificado correctamente");
    return new Response(challenge, {
      status: 200,
      headers: { "Content-Type": "text/plain" }
    });
  }

  // --- SI ES POST (MENSAJE DESDE WHATSAPP) ---
  if (req.method === "POST") {
    try {
      const body = await req.json();
      console.log("📩 Nuevo mensaje recibido:", body);

      // Inicializar Supabase client si tenemos las credenciales
      if (supabaseUrl && supabaseServiceKey) {
        const supabase = createClient(supabaseUrl, supabaseServiceKey);

        // Procesar mensaje entrante
        const entry = body.entry?.[0];
        const changes = entry?.changes?.[0];
        const value = changes?.value;
        const message = value?.messages?.[0];
        const contact = value?.contacts?.[0];

        if (message && message.type === "text") {
          const phone = message.from;
          const text = message.text?.body || "";
          const wa_id = contact?.wa_id || phone;
          const name = contact?.profile?.name || "";

          console.log(`📱 Mensaje de ${phone}: ${text}`);

          // 1. Obtener o crear cliente
          let customerId: string | null = null;
          
          const { data: existingCustomer } = await supabase
            .from("customers")
            .select("id")
            .eq("phone", phone)
            .single();

          if (existingCustomer) {
            customerId = existingCustomer.id;
            console.log(`✅ Cliente existente: ${customerId}`);
          } else {
            // Crear nuevo cliente
            const { data: newCustomer, error: customerError } = await supabase
              .from("customers")
              .insert({
                phone: phone,
                name: name || null,
                wa_id: wa_id,
                plan: "basic",
              })
              .select("id")
              .single();

            if (customerError) {
              console.error("❌ Error creando cliente:", customerError);
            } else {
              customerId = newCustomer.id;
              console.log(`✅ Nuevo cliente creado: ${customerId}`);
            }
          }

          // 2. Guardar mensaje en la tabla messages
          if (customerId) {
            const { error: messageError } = await supabase
              .from("messages")
              .insert({
                customer_id: customerId,
                phone: phone,
                direction: "inbound",
                message_type: "text",
                content: text,
                ton_data: {
                  text: text.toLowerCase().trim(),
                  from: phone,
                  wa_id: wa_id,
                },
              });

            if (messageError) {
              console.error("❌ Error guardando mensaje:", messageError);
            } else {
              console.log("✅ Mensaje guardado en base de datos");
            }
          }
        }
      }

      return new Response("EVENT_RECEIVED", { status: 200 });
    } catch (error) {
      console.error("❌ Error procesando webhook:", error);
      return new Response("EVENT_RECEIVED", { status: 200 }); // Meta espera 200
    }
  }

  return new Response("OK", { status: 200 });
});
