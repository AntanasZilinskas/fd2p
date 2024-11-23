import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { Session } from 'https://esm.sh/@supabase/functions-js@0.0.3';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
);

const model = new Session('gte-small');

serve(async (req) => {
  try {
    const { initialize } = await req.json();

    if (initialize) {
      // Process all records without embeddings
      const { data, error } = await supabase
        .from('music_features')
        .select('id, title')
        .is('title_embedding', null);

      if (error) {
        console.error('Error fetching records without embeddings:', error);
        return new Response('Error fetching records without embeddings', { status: 500 });
      }

      if (data.length === 0) {
        return new Response('All titles already have embeddings', { status: 200 });
      }

      for (const record of data) {
        const embedding = await model.run(record.title, {
          mean_pool: true,
          normalize: true,
        });

        const { error: updateError } = await supabase
          .from('music_features')
          .update({ title_embedding: embedding })
          .eq('id', record.id);

        if (updateError) {
          console.error(`Error updating embedding for ID ${record.id}:`, updateError);
        }
      }

      return new Response('Embeddings generated for missing records', { status: 200 });
    }

    const { record } = await req.json();
    if (!record || !record.title) {
      return new Response('Invalid request data', { status: 400 });
    }

    const embedding = await model.run(record.title, {
      mean_pool: true,
      normalize: true,
    });

    const { error } = await supabase
      .from('music_features')
      .update({ title_embedding: embedding })
      .eq('id', record.id);

    if (error) {
      console.error('Error updating title embedding:', error);
      return new Response('Error updating title embedding', { status: 500 });
    }

    return new Response('Title embedding generated and stored successfully', { status: 200 });
  } catch (error) {
    console.error('Error processing request:', error);
    return new Response('Error processing request', { status: 500 });
  }
});