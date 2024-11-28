-- Supabase AI is experimental and may produce incorrect answers
-- Always verify the output before executing

drop trigger if exists generate_embedding_trigger on music_features;

create
or replace function call_generate_title_embedding () returns trigger as $$
DECLARE
    response RECORD;
BEGIN
    PERFORM
      http_post(
        'https://dvplamwokfwyvuaskgyk.functions.supabase.co/generate_title_embedding',
        json_build_object('record', NEW)::text,
        'Content-Type=application/json'
      );

    RETURN NEW;
END;
$$ language plpgsql;

create trigger generate_embedding_trigger
after insert
or
update of title on music_features for each row
execute function call_generate_title_embedding ();