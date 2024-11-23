import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/functions-js@2.4.3';
import { Session } from 'https://esm.sh/@supabase/functions-js@0.0.3';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
);

const model = new Session('gte-small');

serve(async (req) => {
  try {
    const { query, top_n = 5 } = await req.json();

    if (!query) {
      return new Response('Query is required', { status: 400 });
    }

    const queryEmbedding = await model.run(query, {
      mean_pool: true,
      normalize: true,
    });

    const { data, error } = await supabase
      .rpc('match_similar_songs', {
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