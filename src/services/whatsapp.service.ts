/**
 * WhatsApp Service
 * Envío de mensajes a través de WhatsApp Cloud API
 */

export interface WhatsAppConfig {
  phoneNumberId: string;
  accessToken: string;
  apiVersion?: string;
}

export interface SendMessageOptions {
  to: string;
  message: string;
  templateName?: string;
  templateParams?: string[];
}

export class WhatsAppService {
  private phoneNumberId: string;
  private accessToken: string;
  private apiVersion: string;
  private baseURL: string;

  constructor(config: WhatsAppConfig) {
    this.phoneNumberId = config.phoneNumberId;
    this.accessToken = config.accessToken;
    this.apiVersion = config.apiVersion || 'v21.0';
    this.baseURL = `https://graph.facebook.com/${this.apiVersion}`;
  }

  /**
   * Envía un mensaje de texto simple
   */
  async sendTextMessage(to: string, message: string): Promise<{ success: boolean; messageId?: string; error?: string }> {
    try {
      const response = await fetch(
        `${this.baseURL}/${this.phoneNumberId}/messages`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.accessToken}`,
          },
          body: JSON.stringify({
            messaging_product: 'whatsapp',
            recipient_type: 'individual',
            to: to.replace(/\D/g, ''), // Solo números
            type: 'text',
            text: {
              preview_url: false,
              body: message,
            },
          }),
        }
      );

      const data = await response.json() as {
        error?: { message?: string };
        messages?: Array<{ id?: string }>;
      };

      if (!response.ok) {
        return {
          success: false,
          error: data.error?.message || 'Failed to send message',
        };
      }

      return {
        success: true,
        messageId: data.messages?.[0]?.id,
      };
    } catch (error) {
      console.error('Error sending WhatsApp message:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      };
    }
  }

  /**
   * Envía un mensaje usando una plantilla (solo para plan Full)
   */
  async sendTemplateMessage(
    to: string,
    templateName: string,
    templateParams: string[] = []
  ): Promise<{ success: boolean; messageId?: string; error?: string }> {
    try {
      const components: any[] = [];

      if (templateParams.length > 0) {
        components.push({
          type: 'body',
          parameters: templateParams.map(param => ({
            type: 'text',
            text: param,
          })),
        });
      }

      const response = await fetch(
        `${this.baseURL}/${this.phoneNumberId}/messages`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.accessToken}`,
          },
          body: JSON.stringify({
            messaging_product: 'whatsapp',
            recipient_type: 'individual',
            to: to.replace(/\D/g, ''),
            type: 'template',
            template: {
              name: templateName,
              language: {
                code: 'es',
              },
              components: components.length > 0 ? components : undefined,
            },
          }),
        }
      );

      const data = await response.json() as {
        error?: { message?: string };
        messages?: Array<{ id?: string }>;
      };

      if (!response.ok) {
        return {
          success: false,
          error: data.error?.message || 'Failed to send template message',
        };
      }

      return {
        success: true,
        messageId: data.messages?.[0]?.id,
      };
    } catch (error) {
      console.error('Error sending WhatsApp template:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      };
    }
  }

  /**
   * Verifica el estado de un número de teléfono
   */
  async verifyPhoneNumber(phoneNumberId: string): Promise<boolean> {
    try {
      const response = await fetch(
        `${this.baseURL}/${phoneNumberId}`,
        {
          method: 'GET',
          headers: {
            'Authorization': `Bearer ${this.accessToken}`,
          },
        }
      );

      return response.ok;
    } catch {
      return false;
    }
  }

  /**
   * Obtiene información de un número de teléfono
   */
  async getPhoneNumberInfo(phoneNumberId: string): Promise<any> {
    try {
      const response = await fetch(
        `${this.baseURL}/${phoneNumberId}`,
        {
          method: 'GET',
          headers: {
            'Authorization': `Bearer ${this.accessToken}`,
          },
        }
      );

      if (!response.ok) {
        throw new Error('Failed to get phone number info');
      }

      return await response.json();
    } catch (error) {
      console.error('Error getting phone number info:', error);
      throw error;
    }
  }
}

