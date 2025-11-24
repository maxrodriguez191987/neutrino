/**
 * TON (Tree Object Notation) Utilities
 * Normalización y conversión de mensajes a formato TON
 */

export interface TONMessage {
  text: string;
  from: string;
  wa_id: string;
  timestamp?: string;
}

export interface TONResponse {
  intent: string;
  product_query?: string;
  quantity?: string;
  response: string;
  confidence?: number;
  metadata?: Record<string, any>;
}

/**
 * Normaliza un texto para TON:
 * - Convierte a minúsculas
 * - Elimina tildes
 * - Elimina caracteres especiales (excepto espacios y letras/números)
 * - Limpia espacios múltiples
 */
export function normalizeText(text: string): string {
  return text
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '') // Elimina tildes
    .replace(/[^a-z0-9\s]/g, '') // Solo letras, números y espacios
    .replace(/\s+/g, ' ') // Espacios múltiples a uno
    .trim();
}

/**
 * Convierte un mensaje de WhatsApp Webhook a formato TON
 */
export function whatsappToTON(webhookData: any): TONMessage {
  const entry = webhookData.entry?.[0];
  const changes = entry?.changes?.[0];
  const value = changes?.value;
  const message = value?.messages?.[0];
  const contact = value?.contacts?.[0];

  const text = message?.text?.body || message?.body || '';
  const from = message?.from || value?.metadata?.phone_number_id || '';
  const wa_id = contact?.wa_id || message?.from || '';

  return {
    text: normalizeText(text),
    from: from.replace(/\D/g, ''), // Solo números
    wa_id: wa_id.replace(/\D/g, ''),
    timestamp: message?.timestamp || new Date().toISOString(),
  };
}

/**
 * Convierte un objeto a formato TON string
 */
export function objectToTON(obj: Record<string, any>): string {
  const lines: string[] = [];
  
  for (const [key, value] of Object.entries(obj)) {
    if (value === null || value === undefined) continue;
    
    if (typeof value === 'string') {
      // Escapar comillas dobles en strings
      const escaped = value.replace(/"/g, '\\"');
      lines.push(`${key}:"${escaped}"`);
    } else if (typeof value === 'number' || typeof value === 'boolean') {
      lines.push(`${key}:${value}`);
    } else if (Array.isArray(value)) {
      lines.push(`${key}:[${value.map(v => typeof v === 'string' ? `"${v}"` : v).join(',')}]`);
    } else if (typeof value === 'object') {
      lines.push(`${key}:{${objectToTON(value).replace(/\n/g, ' ')}}`);
    }
  }
  
  return lines.join('\n');
}

/**
 * Parsea un string TON a objeto
 */
export function parseTON(tonString: string): Record<string, any> {
  const result: Record<string, any> = {};
  const lines = tonString.split('\n').filter(line => line.trim());
  
  for (const line of lines) {
    const match = line.match(/^(\w+):(.+)$/);
    if (!match) continue;
    
    const [, key, value] = match;
    const trimmedValue = value.trim();
    
    // String entre comillas
    if (trimmedValue.startsWith('"') && trimmedValue.endsWith('"')) {
      result[key] = trimmedValue.slice(1, -1).replace(/\\"/g, '"');
    }
    // Número
    else if (/^-?\d+\.?\d*$/.test(trimmedValue)) {
      result[key] = parseFloat(trimmedValue);
    }
    // Booleano
    else if (trimmedValue === 'true' || trimmedValue === 'false') {
      result[key] = trimmedValue === 'true';
    }
    // Array
    else if (trimmedValue.startsWith('[') && trimmedValue.endsWith(']')) {
      const content = trimmedValue.slice(1, -1);
      result[key] = content.split(',').map(v => {
        const trimmed = v.trim();
        if (trimmed.startsWith('"') && trimmed.endsWith('"')) {
          return trimmed.slice(1, -1);
        }
        return parseFloat(trimmed) || trimmed;
      });
    }
    // Otro (string sin comillas)
    else {
      result[key] = trimmedValue;
    }
  }
  
  return result;
}

/**
 * Crea un mensaje TON de entrada estándar
 */
export function createTONInput(message: TONMessage): string {
  return objectToTON({
    text: message.text,
    from: message.from,
    wa_id: message.wa_id,
    timestamp: message.timestamp,
  });
}

/**
 * Valida que un string sea TON válido
 */
export function validateTON(tonString: string): boolean {
  try {
    parseTON(tonString);
    return true;
  } catch {
    return false;
  }
}

