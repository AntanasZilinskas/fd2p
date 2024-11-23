// Setup type definitions for built-in Supabase Runtime APIs
/// <reference types="https://edge-runtime.supabase.com/types/v1" />

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

const model = new Supabase.ai.Session('gte-small');

Deno.serve(async (req) => {
  try {
    const { query, top_n = 5 } = await req.json();

    if (!query) {
      return new Response('Query is required', { status: 400 });
    }

    const queryEmbedding = await model.run(query, {
      mean_pool: true,
      normalize: true,
    });

    const { data, error } = await supabase.rpc('match_similar_songs', {
      input_vector: queryEmbedding,
      top_n,
    });

    if (error) {
      console.error('Error fetching similar songs:', error);
      return new Response('Error fetching similar songs', { status: 500 });
    }

    return new Response(JSON.stringify(data), { status: 200 });
  } catch (error) {
    console.error('Error processing request:', error);
    return new Response('Error processing request', { status: 500 });
  }
});