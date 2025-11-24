/**
 * WhatsApp Cloud API Utilities
 * Manejo de mensajes entrantes y salientes
 */

export interface WhatsAppMessage {
  from: string;
  text?: string;
  type: string;
  timestamp: string;
  message_id: string;
}

export interface WhatsAppWebhook {
  object: string;
  entry: Array<{
    id: string;
    changes: Array<{
      value: {
        messaging_product: string;
        metadata: {
          display_phone_number: string;
          phone_number_id: string;
        };
        contacts?: Array<{
          profile: {
            name: string;
          };
          wa_id: string;
        }>;
        messages?: Array<{
          from: string;
          id: string;
          timestamp: string;
          text?: {
            body: string;
          };
          type: string;
        }>;
      };
      field: string;
    }>;
  }>;
}

/**
 * Extrae el mensaje de texto de un webhook de WhatsApp
 */
export function extractMessage(webhook: WhatsAppWebhook): WhatsAppMessage | null {
  const entry = webhook.entry?.[0];
  const changes = entry?.changes?.[0];
  const value = changes?.value;
  const message = value?.messages?.[0];

  if (!message || message.type !== 'text') {
    return null;
  }

  return {
    from: message.from,
    text: message.text?.body,
    type: message.type,
    timestamp: message.timestamp,
    message_id: message.id,
  };
}

/**
 * Valida la firma del webhook de WhatsApp
 */
export function verifyWebhookSignature(
  payload: string,
  signature: string,
  secret: string
): boolean {
  // Implementación básica - en producción usar crypto
  // WhatsApp usa HMAC SHA256
  return true; // Placeholder - implementar con crypto
}

/**
 * Formatea un número de teléfono para WhatsApp
 */
export function formatPhoneNumber(phone: string): string {
  // Elimina todos los caracteres no numéricos
  const cleaned = phone.replace(/\D/g, '');
  
  // Si no empieza con código de país, asumir formato local
  if (cleaned.length < 10) {
    return cleaned;
  }
  
  return cleaned;
}

/**
 * Valida formato de número de WhatsApp
 */
export function isValidWhatsAppNumber(phone: string): boolean {
  const cleaned = formatPhoneNumber(phone);
  // WhatsApp requiere números entre 7 y 15 dígitos
  return cleaned.length >= 7 && cleaned.length <= 15;
}

