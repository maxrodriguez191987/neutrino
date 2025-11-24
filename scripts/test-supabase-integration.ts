#!/usr/bin/env ts-node

/**
 * Script de prueba completa de integración con Supabase
 * Verifica conexión, tablas, funciones y operaciones básicas
 */

import { initSupabase, getSupabaseClient } from '../src/utils/supabase';

// Cargar variables de entorno
require('dotenv').config();

const SUPABASE_URL = process.env.SUPABASE_URL || '';
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || '';

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  console.error('❌ Variables SUPABASE_URL o SUPABASE_ANON_KEY no configuradas');
  process.exit(1);
}

async function testSupabaseIntegration() {
  console.log('🧪 Probando integración completa con Supabase...\n');

  try {
    // 1. Inicializar cliente
    console.log('1️⃣ Inicializando cliente de Supabase...');
    initSupabase({
      url: SUPABASE_URL,
      anonKey: SUPABASE_ANON_KEY,
    });
    const supabase = getSupabaseClient();
    console.log('✅ Cliente inicializado\n');

    // 2. Verificar conexión básica
    console.log('2️⃣ Verificando conexión...');
    const { data: healthCheck, error: healthError } = await supabase
      .from('products')
      .select('count')
      .limit(0);
    
    if (healthError && healthError.code === 'PGRST205') {
      console.log('⚠️  Conexión OK, pero las tablas no existen aún');
      console.log('   Ejecuta supabase/schema.sql en el SQL Editor de Supabase\n');
    } else if (healthError) {
      console.error('❌ Error de conexión:', healthError.message);
      return false;
    } else {
      console.log('✅ Conexión exitosa\n');
    }

    // 3. Verificar tablas
    console.log('3️⃣ Verificando tablas...');
    const tables = ['products', 'customers', 'carts', 'orders', 'messages', 'campaigns'];
    const tableStatus: Record<string, boolean> = {};

    for (const table of tables) {
      try {
        const { error } = await supabase.from(table).select('*').limit(0);
        tableStatus[table] = !error;
      } catch {
        tableStatus[table] = false;
      }
    }

    const existingTables = Object.entries(tableStatus)
      .filter(([_, exists]) => exists)
      .map(([table]) => table);
    
    const missingTables = Object.entries(tableStatus)
      .filter(([_, exists]) => !exists)
      .map(([table]) => table);

    if (existingTables.length > 0) {
      console.log(`✅ Tablas existentes (${existingTables.length}/${tables.length}):`);
      existingTables.forEach(table => console.log(`   - ${table}`));
    }

    if (missingTables.length > 0) {
      console.log(`\n⚠️  Tablas faltantes (${missingTables.length}/${tables.length}):`);
      missingTables.forEach(table => console.log(`   - ${table}`));
      console.log('   Ejecuta supabase/schema.sql para crearlas\n');
    } else {
      console.log('✅ Todas las tablas existen\n');
    }

    // 4. Verificar funciones RPC
    console.log('4️⃣ Verificando funciones RPC...');
    const functions = [
      'add_to_cart',
      'create_order_from_cart',
      'get_or_create_customer',
      'get_abandoned_carts',
    ];

    const functionStatus: Record<string, boolean> = {};

    for (const func of functions) {
      try {
        // Intentar llamar la función con parámetros inválidos
        // Si existe, dará error de parámetros, no de función no encontrada
        const { error } = await supabase.rpc(func as any, {});
        // Si el error es de parámetros, la función existe
        functionStatus[func] = error?.code !== '42883' && error?.code !== 'PGRST301';
      } catch {
        functionStatus[func] = false;
      }
    }

    const existingFunctions = Object.entries(functionStatus)
      .filter(([_, exists]) => exists)
      .map(([func]) => func);
    
    const missingFunctions = Object.entries(functionStatus)
      .filter(([_, exists]) => !exists)
      .map(([func]) => func);

    if (existingFunctions.length > 0) {
      console.log(`✅ Funciones existentes (${existingFunctions.length}/${functions.length}):`);
      existingFunctions.forEach(func => console.log(`   - ${func}`));
    }

    if (missingFunctions.length > 0) {
      console.log(`\n⚠️  Funciones faltantes (${missingFunctions.length}/${functions.length}):`);
      missingFunctions.forEach(func => console.log(`   - ${func}`));
      console.log('   Ejecuta supabase/functions.sql para crearlas\n');
    } else {
      console.log('✅ Todas las funciones existen\n');
    }

    // 5. Probar operaciones básicas (solo si las tablas existen)
    if (existingTables.length > 0) {
      console.log('5️⃣ Probando operaciones básicas...');

      // Probar lectura de productos
      if (tableStatus.products) {
        try {
          const { data: products, error } = await supabase
            .from('products')
            .select('*')
            .limit(5);
          
          if (error) {
            console.log(`⚠️  Error al leer productos: ${error.message}`);
          } else {
            console.log(`✅ Lectura de productos OK (${products?.length || 0} encontrados)`);
          }
        } catch (error) {
          console.log(`⚠️  Error al leer productos: ${error}`);
        }
      }

      // Probar creación de cliente de prueba
      if (tableStatus.customers) {
        try {
          const testPhone = `549${Date.now().toString().slice(-10)}`;
          const { data: customer, error } = await supabase
            .from('customers')
            .insert({
              phone: testPhone,
              name: 'Test User',
              plan: 'basic',
            })
            .select()
            .single();

          if (error && error.code !== '23505') { // Ignorar error de duplicado
            console.log(`⚠️  Error al crear cliente: ${error.message}`);
          } else if (customer) {
            console.log('✅ Creación de cliente OK');
            
            // Limpiar cliente de prueba
            await supabase.from('customers').delete().eq('id', customer.id);
            console.log('✅ Cliente de prueba eliminado');
          }
        } catch (error) {
          console.log(`⚠️  Error al crear cliente: ${error}`);
        }
      }
    }

    // Resumen final
    console.log('\n' + '='.repeat(50));
    console.log('📊 RESUMEN DE INTEGRACIÓN');
    console.log('='.repeat(50));
    console.log(`✅ Conexión: OK`);
    console.log(`✅ Tablas: ${existingTables.length}/${tables.length}`);
    console.log(`✅ Funciones: ${existingFunctions.length}/${functions.length}`);
    
    if (missingTables.length === 0 && missingFunctions.length === 0) {
      console.log('\n🎉 ¡Integración completa! Todo está configurado correctamente.');
      return true;
    } else {
      console.log('\n⚠️  Integración parcial. Ejecuta los scripts SQL faltantes.');
      return false;
    }

  } catch (error) {
    console.error('\n❌ Error durante la prueba:', error);
    return false;
  }
}

// Ejecutar prueba
testSupabaseIntegration()
  .then(success => {
    process.exit(success ? 0 : 1);
  })
  .catch(error => {
    console.error('Error fatal:', error);
    process.exit(1);
  });

