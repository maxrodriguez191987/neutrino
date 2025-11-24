// supabase/functions/whatsapp-webhook/index.ts
// @ts-ignore - Deno runtime
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
// @ts-ignore - Deno runtime
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// @ts-ignore - Deno global object
const ACCESS_TOKEN = Deno.env.get("WHATSAPP_ACCESS_TOKEN") || "";
// @ts-ignore - Deno global object
const PHONE_ID = Deno.env.get("WHATSAPP_PHONE_NUMBER_ID") || "";
// @ts-ignore - Deno global object
const VERIFY_TOKEN = Deno.env.get("WHATSAPP_VERIFY_TOKEN") || "mi_token_secreto_123";
// @ts-ignore - Deno global object
const supabaseUrl = Deno.env.get("SUPABASE_URL") || Deno.env.get("PROJECT_URL") || "";
// @ts-ignore - Deno global object
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || Deno.env.get("SERVICE_ROLE_KEY") || "";

serve(async (req: Request) => {
  const method = req.method;

  // -----------------------------------------------
  // VERIFY WEBHOOK (OFFICIAL META FORMAT)
  // -----------------------------------------------
  if (method === "GET") {
    const url = new URL(req.url);

    const mode = url.searchParams.get("hub.mode");
    const token = url.searchParams.get("hub.verify_token");
    const challenge = url.searchParams.get("hub.challenge");

    if (mode === "subscribe" && token === VERIFY_TOKEN) {
      console.log("✅ Webhook verificado correctamente");
      return new Response(challenge, {
        status: 200,
        headers: { "Content-Type": "text/plain" }
      });
    }

    return new Response("Forbidden", { status: 403 });
  }

  // -----------------------------------------------
  // HANDLE MESSAGES (OFFICIAL META FORMAT)
  // -----------------------------------------------
  if (method === "POST") {
    try {
      const body = await req.json();

      const entry = body.entry?.[0];
      const changes = entry?.changes?.[0];
      const value = changes?.value;
      const msg = value?.messages?.[0];
      const contact = value?.contacts?.[0];

      if (!msg) {
        console.log("⚠️ No message in webhook payload");
        return new Response("OK", { status: 200 });
      }

      // Solo procesar mensajes de texto por ahora
      if (msg.type !== "text") {
        console.log(`⚠️ Message type not supported: ${msg.type}`);
        return new Response("OK", { status: 200 });
      }

      const from = msg.from;
      const text = msg.text?.body || "";
      const wa_id = contact?.wa_id || from;
      const name = contact?.profile?.name || "";

      console.log(`📱 Mensaje de ${from}: ${text}`);

      // Guardar en Supabase
      let customerId: string | null = null;
      
      if (supabaseUrl && supabaseServiceKey) {
        try {
          const supabase = createClient(supabaseUrl, supabaseServiceKey);

          // 1. Obtener o crear cliente
          const { data: existingCustomer } = await supabase
            .from("customers")
            .select("id")
            .eq("phone", from)
            .single();

          if (existingCustomer) {
            customerId = existingCustomer.id;
            console.log(`✅ Cliente existente: ${customerId}`);
          } else {
            // Crear nuevo cliente
            const { data: newCustomer, error: customerError } = await supabase
              .from("customers")
              .insert({
                phone: from,
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
                phone: from,
                direction: "inbound",
                message_type: "text",
                content: text,
                ton_data: {
                  text: text.toLowerCase().trim(),
                  from: from,
                  wa_id: wa_id,
                },
              });

            if (messageError) {
              console.error("❌ Error guardando mensaje:", messageError);
            } else {
              console.log("✅ Mensaje guardado en base de datos");
            }
          }
        } catch (error) {
          console.error("❌ Error con Supabase:", error);
          // Continuar aunque falle Supabase
        }
      }

      // -----------------------------------------------
      // RESPUESTAS AUTOMÁTICAS (BÁSICAS)
      // -----------------------------------------------
      const textLower = text.toLowerCase().trim();
      let reply = "Hola! 👋 Gracias por contactarnos. ¿En qué puedo ayudarte?";

      // Respuestas básicas (se puede mejorar con IA después)
      if (textLower.includes("hola") || textLower.includes("hi") || textLower.includes("buenas")) {
        reply = "¡Hola! 👋 Bienvenido. ¿Qué estás buscando?";
      } else if (textLower.includes("precio") || textLower.includes("precios") || textLower.includes("costo")) {
        reply = "Nuestros precios están disponibles. ¿Qué producto te interesa?";
      } else if (textLower.includes("comprar") || textLower.includes("quiero") || textLower.includes("necesito")) {
        reply = "Perfecto! ¿Qué producto te gustaría comprar?";
      } else if (textLower.includes("producto") || textLower.includes("productos") || textLower.includes("catálogo")) {
        reply = "Tenemos varios productos disponibles. ¿Qué tipo de producto buscas?";
      }

      // Enviar respuesta automática
      if (ACCESS_TOKEN && PHONE_ID) {
        try {
          await sendMessage(from, reply);
          console.log(`✅ Respuesta enviada a ${from}`);
        } catch (error) {
          console.error("❌ Error enviando respuesta:", error);
        }
      }

      return new Response("OK", { status: 200 });
    } catch (error) {
      console.error("❌ Error procesando webhook:", error);
      return new Response("OK", { status: 200 }); // Meta espera 200 incluso si hay error
    }
  }

  return new Response("Not allowed", { status: 405 });
});

// -----------------------------------------------
// FUNCIÓN PARA ENVIAR MENSAJES
// -----------------------------------------------
async function sendMessage(to: string, text: string) {
  if (!ACCESS_TOKEN || !PHONE_ID) {
    throw new Error("WhatsApp credentials not configured");
  }

  const url = `https://graph.facebook.com/v21.0/${PHONE_ID}/messages`;

  const payload = {
    messaging_product: "whatsapp",
    recipient_type: "individual",
    to,
    type: "text",
    text: {
      preview_url: false,
      body: text,
    },
  };

  const response = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${ACCESS_TOKEN}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`WhatsApp API error: ${response.status} - ${error}`);
  }

  const result = await response.json();
  return result;
}
