/**
 * Orders Service
 * Gestión de pedidos
 */

import { getSupabaseClient, Order, OrderItem, Cart } from '../utils/supabase';
import { CartService } from './cart.service';

export class OrdersService {
  private cartService: CartService;

  constructor() {
    this.cartService = new CartService();
  }

  /**
   * Crea un pedido desde el carrito
   */
  async createOrderFromCart(customerId: string): Promise<Order> {
    const supabase = getSupabaseClient();

    // Obtener carrito
    const cart = await this.cartService.getCart(customerId);
    if (!cart || cart.items.length === 0) {
      throw new Error('Cart is empty');
    }

    // Validar stock
    for (const item of cart.items) {
      const { data: product } = await supabase
        .from('products')
        .select('stock')
        .eq('id', item.product_id)
        .single();

      if (!product || product.stock < item.quantity) {
        throw new Error(`Insufficient stock for ${item.name}`);
      }
    }

    // Calcular total
    const total = this.cartService.calculateTotal(cart.items);

    // Crear pedido
    const { data: order, error } = await supabase
      .from('orders')
      .insert({
        customer_id: customerId,
        items: cart.items,
        total,
        status: 'pending',
        payment_status: 'pending',
      })
      .select()
      .single();

    if (error || !order) {
      throw new Error(`Failed to create order: ${error?.message}`);
    }

    // Limpiar carrito
    await this.cartService.clearCart(customerId);

    return {
      ...order,
      items: order.items as OrderItem[],
    };
  }

  /**
   * Obtiene un pedido por ID
   */
  async getOrder(orderId: string): Promise<Order | null> {
    const supabase = getSupabaseClient();

    const { data, error } = await supabase
      .from('orders')
      .select('*')
      .eq('id', orderId)
      .maybeSingle();

    if (error) {
      throw new Error(`Failed to get order: ${error.message}`);
    }

    if (!data) {
      return null;
    }

    return {
      ...data,
      items: (data.items as OrderItem[]) || [],
    };
  }

  /**
   * Obtiene todos los pedidos de un cliente
   */
  async getCustomerOrders(customerId: string): Promise<Order[]> {
    const supabase = getSupabaseClient();

    const { data, error } = await supabase
      .from('orders')
      .select('*')
      .eq('customer_id', customerId)
      .order('created_at', { ascending: false });

    if (error) {
      throw new Error(`Failed to get orders: ${error.message}`);
    }

    return (data || []).map(order => ({
      ...order,
      items: (order.items as OrderItem[]) || [],
    }));
  }

  /**
   * Actualiza el estado de un pedido
   */
  async updateOrderStatus(
    orderId: string,
    status: Order['status'],
    paymentStatus?: Order['payment_status']
  ): Promise<Order> {
    const supabase = getSupabaseClient();

    const updateData: any = {
      status,
      updated_at: new Date().toISOString(),
    };

    if (paymentStatus) {
      updateData.payment_status = paymentStatus;
    }

    const { data, error } = await supabase
      .from('orders')
      .update(updateData)
      .eq('id', orderId)
      .select()
      .single();

    if (error || !data) {
      throw new Error(`Failed to update order: ${error?.message}`);
    }

    return {
      ...data,
      items: (data.items as OrderItem[]) || [],
    };
  }

  /**
   * Formatea un pedido como mensaje de texto
   */
  formatOrderMessage(order: Order): string {
    const itemsText = order.items
      .map(
        item =>
          `• ${item.name} x${item.quantity} - $${(item.price * item.quantity).toFixed(2)}`
      )
      .join('\n');

    const statusEmoji: Record<string, string> = {
      pending: '⏳',
      confirmed: '✅',
      processing: '🔄',
      shipped: '📦',
      delivered: '🎉',
      cancelled: '❌',
    };

    return `📋 *Pedido #${order.id.slice(0, 8)}*\n\n${itemsText}\n\n*Total: $${order.total.toFixed(2)}*\n*Estado: ${statusEmoji[order.status] || ''} ${order.status}*`;
  }

  /**
   * Obtiene estadísticas de pedidos
   */
  async getOrderStats(customerId?: string): Promise<{
    total: number;
    totalRevenue: number;
    byStatus: Record<string, number>;
  }> {
    const supabase = getSupabaseClient();

    let query = supabase.from('orders').select('*');

    if (customerId) {
      query = query.eq('customer_id', customerId);
    }

    const { data, error } = await query;

    if (error) {
      throw new Error(`Failed to get order stats: ${error.message}`);
    }

    const orders = (data || []) as Order[];

    const stats = {
      total: orders.length,
      totalRevenue: orders.reduce((sum, order) => sum + Number(order.total), 0),
      byStatus: {} as Record<string, number>,
    };

    orders.forEach(order => {
      stats.byStatus[order.status] = (stats.byStatus[order.status] || 0) + 1;
    });

    return stats;
  }
}

