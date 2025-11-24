/**
 * Supabase Client Utilities
 * Configuración y helpers para Supabase
 */

import { createClient, SupabaseClient } from '@supabase/supabase-js';

export interface SupabaseConfig {
  url: string;
  anonKey: string;
  serviceRoleKey?: string;
}

let supabaseClient: SupabaseClient | null = null;
let supabaseAdminClient: SupabaseClient | null = null;

/**
 * Inicializa el cliente de Supabase
 */
export function initSupabase(config: SupabaseConfig): SupabaseClient {
  if (!supabaseClient) {
    supabaseClient = createClient(config.url, config.anonKey, {
      auth: {
        persistSession: false,
      },
    });
  }
  return supabaseClient;
}

/**
 * Obtiene el cliente de Supabase (requiere inicialización previa)
 */
export function getSupabaseClient(): SupabaseClient {
  if (!supabaseClient) {
    throw new Error('Supabase client not initialized. Call initSupabase() first.');
  }
  return supabaseClient;
}

/**
 * Inicializa el cliente admin de Supabase (con service role key)
 */
export function initSupabaseAdmin(config: SupabaseConfig): SupabaseClient {
  if (!config.serviceRoleKey) {
    throw new Error('Service role key is required for admin client');
  }
  
  if (!supabaseAdminClient) {
    supabaseAdminClient = createClient(config.url, config.serviceRoleKey, {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    });
  }
  return supabaseAdminClient;
}

/**
 * Obtiene el cliente admin de Supabase
 */
export function getSupabaseAdminClient(): SupabaseClient {
  if (!supabaseAdminClient) {
    throw new Error('Supabase admin client not initialized. Call initSupabaseAdmin() first.');
  }
  return supabaseAdminClient;
}

/**
 * Tipos de datos para las tablas
 */
export interface Product {
  id: string;
  name: string;
  price: number;
  stock: number;
  image_url?: string;
  description?: string;
  category?: string;
  created_at: string;
  updated_at: string;
}

export interface Customer {
  id: string;
  phone: string;
  name?: string;
  email?: string;
  plan: 'basic' | 'pro' | 'full';
  wa_id?: string;
  metadata?: Record<string, any>;
  created_at: string;
  updated_at: string;
}

export interface Cart {
  id: string;
  customer_id: string;
  items: CartItem[];
  updated_at: string;
  expires_at?: string;
}

export interface CartItem {
  product_id: string;
  name: string;
  price: number;
  quantity: number;
}

export interface Order {
  id: string;
  customer_id: string;
  items: OrderItem[];
  total: number;
  status: 'pending' | 'confirmed' | 'processing' | 'shipped' | 'delivered' | 'cancelled';
  payment_status: 'pending' | 'paid' | 'failed' | 'refunded';
  shipping_address?: Record<string, any>;
  notes?: string;
  created_at: string;
  updated_at: string;
}

export interface OrderItem {
  product_id: string;
  name: string;
  price: number;
  quantity: number;
}

