// Setup type definitions for built-in Supabase Runtime APIs
/// <reference types="https://edge-runtime.supabase.com/types/v1" />

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// Initialize Supabase client
const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const supabaseServiceRoleKey =
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

// Initialize the AI model session
const model = new Supabase.ai.Session('gte-small');

Deno.serve(async (req) => {
  try {
    const { initialize, record } = await req.json();

    if (initialize) {
      const batchSize = 2; // Process 25 titles at a time

      async function processBatch() {
        // Get a batch of titles without embeddings
        const { data: titles, error } = await supabase
          .from('music_features')
          .select('id, title')
          .is('title_embedding', null)
          .limit(batchSize);

        if (error) {
          console.error('Error fetching titles without embeddings:', error);
          throw error;
        }

        if (!titles || titles.length === 0) {
          console.log('No more titles without embeddings.');
          return;
        }

        // Generate embeddings for the batch
        const embeddings = await Promise.all(
          titles.map(async ({ id, title }) => {
            try {
              const embedding = await model.run(title, {
                mean_pool: true,
                normalize: true,
              });
              return { id, title_embedding: embedding };
            } catch (err) {
              console.error(`Error generating embedding for ID ${id}:`, err);
              return null; // Handle failed embeddings
            }
          })
        );

        // Filter out any null embeddings due to errors
        const validEmbeddings = embeddings.filter((e) => e !== null);

        if (validEmbeddings.length > 0) {
          // Update embeddings in the database
          const { error: updateError } = await supabase
            .from('music_features')
            .upsert(validEmbeddings);

          if (updateError) {
            console.error('Error updating embeddings:', updateError);
            throw updateError;
          }
        }

        // If the batch size equals batchSize, there may be more records
        if (titles.length === batchSize) {
          console.log('Processing next batch...');
          try {
            await processBatch();
          } catch (err) {
            console.error('Error processing next batch:', err);
            throw err;
          }
        } else {
          console.log('All batches processed.');
        }
      }

      try {
        await processBatch(); // Start the recursive process
      } catch (err) {
        console.error('Error during batch processing:', err);
        return new Response('Error during batch processing', { status: 500 });
      }

      return new Response(
        'Embeddings generated for all missing records',
        { status: 200 }
      );
    }

    // Single record processing
    if (!record || !record.title) {
      return new Response('Invalid request data', { status: 400 });
    }

    try {
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
        return new Response('Error updating title embedding', {
          status: 500,
        });
      }

      return new Response(
        'Title embedding generated and stored successfully',
        { status: 200 }
      );
    } catch (err) {
      console.error('Error generating embedding:', err);
      return new Response('Error generating embedding', { status: 500 });
    }
  } catch (error) {
    console.error('Error processing request:', error);
    return new Response('Error processing request', { status: 500 });
  }
});