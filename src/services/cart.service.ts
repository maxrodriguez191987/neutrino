/**
 * Cart Service
 * Gestión de carritos de compra
 */

import { getSupabaseClient, Cart, CartItem, Product } from '../utils/supabase';

export class CartService {
  /**
   * Obtiene o crea un carrito para un cliente
   */
  async getOrCreateCart(customerId: string): Promise<Cart> {
    const supabase = getSupabaseClient();

    // Buscar carrito existente
    const { data: existingCart, error: fetchError } = await supabase
      .from('carts')
      .select('*')
      .eq('customer_id', customerId)
      .maybeSingle();

    if (existingCart && !fetchError) {
      return {
        ...existingCart,
        items: existingCart.items as CartItem[],
      };
    }

    // Crear nuevo carrito
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7); // Expira en 7 días

    const { data: newCart, error: createError } = await supabase
      .from('carts')
      .insert({
        customer_id: customerId,
        items: [],
        expires_at: expiresAt.toISOString(),
      })
      .select()
      .single();

    if (createError || !newCart) {
      throw new Error(`Failed to create cart: ${createError?.message}`);
    }

    return {
      ...newCart,
      items: (newCart.items as CartItem[]) || [],
    };
  }

  /**
   * Agrega un producto al carrito
   */
  async addToCart(
    customerId: string,
    productId: string,
    quantity: number = 1
  ): Promise<Cart> {
    const supabase = getSupabaseClient();

    // Obtener información del producto
    const { data: product, error: productError } = await supabase
      .from('products')
      .select('*')
      .eq('id', productId)
      .single();

    if (productError || !product) {
      throw new Error(`Product not found: ${productId}`);
    }

    if (product.stock < quantity) {
      throw new Error(`Insufficient stock. Available: ${product.stock}`);
    }

    // Obtener o crear carrito
    const cart = await this.getOrCreateCart(customerId);

    // Verificar si el producto ya está en el carrito
    const existingItemIndex = cart.items.findIndex(
      item => item.product_id === productId
    );

    let updatedItems: CartItem[];

    if (existingItemIndex >= 0) {
      // Actualizar cantidad
      updatedItems = [...cart.items];
      updatedItems[existingItemIndex].quantity += quantity;
    } else {
      // Agregar nuevo item
      updatedItems = [
        ...cart.items,
        {
          product_id: product.id,
          name: product.name,
          price: product.price,
          quantity,
        },
      ];
    }

    // Actualizar carrito
    const { data: updatedCart, error: updateError } = await supabase
      .from('carts')
      .update({
        items: updatedItems,
        updated_at: new Date().toISOString(),
      })
      .eq('id', cart.id)
      .select()
      .single();

    if (updateError || !updatedCart) {
      throw new Error(`Failed to update cart: ${updateError?.message}`);
    }

    return {
      ...updatedCart,
      items: updatedCart.items as CartItem[],
    };
  }

  /**
   * Obtiene el carrito de un cliente
   */
  async getCart(customerId: string): Promise<Cart | null> {
    const supabase = getSupabaseClient();

    const { data, error } = await supabase
      .from('carts')
      .select('*')
      .eq('customer_id', customerId)
      .maybeSingle();

    if (error) {
      throw new Error(`Failed to get cart: ${error.message}`);
    }

    if (!data) {
      return null;
    }

    return {
      ...data,
      items: (data.items as CartItem[]) || [],
    };
  }

  /**
   * Elimina un producto del carrito
   */
  async removeFromCart(customerId: string, productId: string): Promise<Cart> {
    const supabase = getSupabaseClient();

    const cart = await this.getCart(customerId);
    if (!cart) {
      throw new Error('Cart not found');
    }

    const updatedItems = cart.items.filter(
      item => item.product_id !== productId
    );

    const { data: updatedCart, error } = await supabase
      .from('carts')
      .update({
        items: updatedItems,
        updated_at: new Date().toISOString(),
      })
      .eq('id', cart.id)
      .select()
      .single();

    if (error || !updatedCart) {
      throw new Error(`Failed to remove from cart: ${error?.message}`);
    }

    return {
      ...updatedCart,
      items: updatedCart.items as CartItem[],
    };
  }

  /**
   * Limpia el carrito
   */
  async clearCart(customerId: string): Promise<void> {
    const supabase = getSupabaseClient();

    const { error } = await supabase
      .from('carts')
      .update({
        items: [],
        updated_at: new Date().toISOString(),
      })
      .eq('customer_id', customerId);

    if (error) {
      throw new Error(`Failed to clear cart: ${error.message}`);
    }
  }

  /**
   * Calcula el total del carrito
   */
  calculateTotal(items: CartItem[]): number {
    return items.reduce((total, item) => total + item.price * item.quantity, 0);
  }

  /**
   * Formatea el carrito como mensaje de texto
   */
  formatCartMessage(cart: Cart): string {
    if (cart.items.length === 0) {
      return 'Tu carrito está vacío.';
    }

    const itemsText = cart.items
      .map(
        item =>
          `• ${item.name} x${item.quantity} - $${(item.price * item.quantity).toFixed(2)}`
      )
      .join('\n');

    const total = this.calculateTotal(cart.items);

    return `🛒 *Tu carrito:*\n\n${itemsText}\n\n*Total: $${total.toFixed(2)}*`;
  }

  /**
   * Obtiene carritos abandonados (sin actividad en X días)
   */
  async getAbandonedCarts(days: number = 3): Promise<Cart[]> {
    const supabase = getSupabaseClient();

    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - days);

    const { data, error } = await supabase
      .from('carts')
      .select('*')
      .lt('updated_at', cutoffDate.toISOString())
      .not('items', 'eq', '[]')
      .order('updated_at', { ascending: true });

    if (error) {
      throw new Error(`Failed to get abandoned carts: ${error.message}`);
    }

    return (data || []).map(cart => ({
      ...cart,
      items: (cart.items as CartItem[]) || [],
    }));
  }
}

