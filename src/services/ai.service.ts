/**
 * AI Service
 * Integración con OpenAI para interpretación de intenciones usando TON
 */

import { TONResponse, parseTON } from '../utils/ton';

export interface AIConfig {
  apiKey: string;
  model?: string;
  baseURL?: string;
}

export class AIService {
  private apiKey: string;
  private model: string;
  private baseURL: string;

  constructor(config: AIConfig) {
    this.apiKey = config.apiKey;
    this.model = config.model || 'gpt-4o-mini';
    this.baseURL = config.baseURL || 'https://api.openai.com/v1';
  }

  /**
   * Interpreta un mensaje TON usando OpenAI
   */
  async interpretIntent(
    tonInput: string,
    promptTemplate: string,
    plan: 'basic' | 'pro' | 'full' = 'basic'
  ): Promise<TONResponse> {
    const systemPrompt = this.getSystemPrompt(plan);
    const userPrompt = promptTemplate.replace('{{TON_INPUT}}', tonInput);

    try {
      const response = await fetch(`${this.baseURL}/chat/completions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.apiKey}`,
        },
        body: JSON.stringify({
          model: this.model,
          messages: [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: userPrompt },
          ],
          temperature: 0.3,
          response_format: { type: 'text' }, // Forzamos texto para TON
        }),
      });

      if (!response.ok) {
        const error = await response.json() as { error?: { message?: string } };
        throw new Error(`OpenAI API error: ${error.error?.message || 'Unknown error'}`);
      }

      const data = await response.json() as {
        choices: Array<{
          message: {
            content: string;
          };
        }>;
      };
      const tonOutput = data.choices[0]?.message?.content || '';

      // Parsear respuesta TON
      const parsed = parseTON(tonOutput);
      
      return {
        intent: parsed.intent || 'otro',
        product_query: parsed.product_query,
        quantity: parsed.quantity || '1',
        response: parsed.response || 'Lo siento, no pude entender tu mensaje.',
        confidence: parsed.confidence,
        metadata: parsed.metadata,
      };
    } catch (error) {
      console.error('Error interpreting intent:', error);
      throw error;
    }
  }

  /**
   * Obtiene el prompt del sistema según el plan
   */
  private getSystemPrompt(plan: 'basic' | 'pro' | 'full'): string {
    const basePrompt = `Eres un asistente de ventas por WhatsApp. Tu tarea es interpretar mensajes de clientes y responder en formato TON (Tree Object Notation).

Formato de salida TON requerido:
intent:"tipo_de_intencion"
product_query:"nombre_del_producto" (opcional)
quantity:"1" (opcional)
response:"respuesta_amigable_al_cliente"
confidence:0.95 (opcional)

Intenciones disponibles según el plan:`;

    const basicIntents = `
- saludo
- pregunta_producto
- otro`;

    const proIntents = `
- saludo
- pregunta_producto
- agregar_carrito
- consultar_carrito
- confirmar_pedido
- otro`;

    const fullIntents = `
- saludo
- pregunta_producto
- agregar_carrito
- consultar_carrito
- confirmar_pedido
- carrito_abandonado
- oferta_personalizada
- mensaje_marketing
- otro`;

    const intents = plan === 'basic' ? basicIntents : plan === 'pro' ? proIntents : fullIntents;

    return `${basePrompt}${intents}

IMPORTANTE: Siempre responde SOLO en formato TON válido, sin explicaciones adicionales.`;
  }

  /**
   * Genera una respuesta personalizada para marketing (plan Full)
   */
  async generateMarketingMessage(
    customerName: string,
    products: Array<{ name: string; price: number }>,
    campaignType: 'abandoned_cart' | 'weekly_offer' | 'marketing'
  ): Promise<string> {
    const prompt = this.getMarketingPrompt(customerName, products, campaignType);

    try {
      const response = await fetch(`${this.baseURL}/chat/completions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.apiKey}`,
        },
        body: JSON.stringify({
          model: this.model,
          messages: [
            {
              role: 'system',
              content: 'Eres un experto en marketing por WhatsApp. Genera mensajes cortos, amigables y persuasivos (máximo 300 caracteres).',
            },
            { role: 'user', content: prompt },
          ],
          temperature: 0.7,
          max_tokens: 200,
        }),
      });

      if (!response.ok) {
        throw new Error('Failed to generate marketing message');
      }

      const data = await response.json() as {
        choices: Array<{
          message: {
            content?: string;
          };
        }>;
      };
      return data.choices[0]?.message?.content?.trim() || '';
    } catch (error) {
      console.error('Error generating marketing message:', error);
      throw error;
    }
  }

  private getMarketingPrompt(
    customerName: string,
    products: Array<{ name: string; price: number }>,
    campaignType: string
  ): string {
    const productList = products.map(p => `- ${p.name} ($${p.price})`).join('\n');

    switch (campaignType) {
      case 'abandoned_cart':
        return `Genera un mensaje para ${customerName} recordándole que tiene productos en su carrito:\n${productList}\n\nMensaje amigable y con sentido de urgencia.`;
      case 'weekly_offer':
        return `Genera un mensaje de oferta semanal para ${customerName} con estos productos:\n${productList}\n\nMensaje promocional atractivo.`;
      case 'marketing':
        return `Genera un mensaje de marketing personalizado para ${customerName} sobre estos productos:\n${productList}\n\nMensaje persuasivo y personalizado.`;
      default:
        return `Genera un mensaje para ${customerName} sobre estos productos:\n${productList}`;
    }
  }
}

