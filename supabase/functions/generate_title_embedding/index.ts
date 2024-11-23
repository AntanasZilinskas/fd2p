// Setup type definitions for built-in Supabase Runtime APIs
/// <reference types="https://esm.sh/@supabase/functions-js/src/edge-runtime.d.ts" />

import { createClient } from '@supabase/supabase-js';

const model = new Supabase.ai.Session('gte-small');

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

Deno.serve(async (req) => {
  try {
    const { initialize, record } = await req.json();

    if (initialize) {
      // Process all records without embeddings
      const { data, error } = await supabase
        .from('music_features')
        .select('id, title')
        .is('title_embedding', null);

      if (error) {
        console.error('Error fetching records without embeddings:', error);
        return new Response('Error fetching records without embeddings', {
          status: 500,
        });
      }

      if (data.length === 0) {
        return new Response('All titles already have embeddings', {
          status: 200,
        });
      }

      for (const record of data) {
        const embedding = (await model.run(record.title, {
          mean_pool: true,
          normalize: true,
        })) as number[];

        const { error: updateError } = await supabase
          .from('music_features')
          .update({ title_embedding: embedding })
          .eq('id', record.id);

        if (updateError) {
          console.error(
            `Error updating embedding for ID ${record.id}:`,
            updateError
          );
        }
      }

      return new Response('Embeddings generated for missing records', {
        status: 200,
      });
    }

    if (!record || !record.title) {
      return new Response('Invalid request data', { status: 400 });
    }

    const embedding = (await model.run(record.title, {
      mean_pool: true,
      normalize: true,
    })) as number[];

    const { error } = await supabase
      .from('music_features')
      .update({ title_embedding: embedding })
      .eq('id', record.id);

    if (error) {
      console.error('Error updating title embedding:', error);
      return new Response('Error updating title embedding', { status: 500 });
    }

    return new Response(
      'Title embedding generated and stored successfully',
      { status: 200 }
    );
  } catch (error) {
    console.error('Error processing request:', error);
    return new Response('Error processing request', { status: 500 });
  }
});