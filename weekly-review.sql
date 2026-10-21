CREATE OR REPLACE FUNCTION private.elementenpuzzle_weekly_review()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_date date;
  v_word text;
  v_symbols text[];
  v_choices text[];
  v_sidewords jsonb;
  v_sideword_total integer;
  v_leaderboard jsonb;
begin
  if auth.uid() is null or coalesce((auth.jwt() ->> 'is_anonymous')::boolean,false) then
    raise exception 'Nur fuer angemeldete Spieler verfuegbar'
      using errcode = '42501';
  end if;

  -- Only completed Sunday/Monday windows can be revealed.
  select w.sunday_date,w.word,w.symbols,w.choices
    into v_date,v_word,v_symbols,v_choices
  from public.elementenpuzzle_weekly_puzzles w
  where w.sunday_date < public.elementenpuzzle_today() - 1
  order by w.sunday_date desc limit 1;

  if v_word is null then
    return jsonb_build_object('available',false,'puzzle_date',v_date);
  end if;

  with eligible as (
    select vw.word,vw.symbols_text,vw.frequency_rank
    from public.elementenpuzzle_valid_words vw
    join public.elementenpuzzle_german_words gw
      on gw.word=vw.word and gw.active
    where vw.active
      and vw.symbol_count=cardinality(v_symbols)
      and vw.word<>lower(v_word)
      and not exists (
        select 1
        from unnest(string_to_array(vw.symbols_text,'|')) s(sym)
        where not (s.sym=any(v_choices))
      )
  )
  select
    (select count(*)::integer from eligible),
    (select coalesce(jsonb_agg(jsonb_build_object(
       'word',top.word,
       'symbols',string_to_array(top.symbols_text,'|')
     ) order by top.frequency_rank nulls last,top.word),'[]'::jsonb)
     from (
       select word,symbols_text,frequency_rank
       from eligible
       order by frequency_rank nulls last,word
       limit 10
     ) top)
  into v_sideword_total,v_sidewords;

  with standings as (
    select
      rank() over (order by a.elapsed_ms asc,a.solved_at asc) as rank,
      coalesce(nullif(u.raw_user_meta_data->>'username',''),
               'Spieler-' || left(a.user_id::text,4)) as username,
      a.elapsed_ms,a.guesses
    from public.elementenpuzzle_weekly_attempts a
    join auth.users u on u.id=a.user_id
    where a.sunday_date=v_date
      and a.solved_at is not null
      and a.elapsed_ms is not null
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'rank',s.rank,'username',s.username,
    'elapsed_ms',s.elapsed_ms,'guesses',s.guesses
  ) order by s.rank),'[]'::jsonb)
  into v_leaderboard
  from (
    select * from standings order by rank
  ) s;

  return jsonb_build_object(
    'available',true,
    'puzzle_date',v_date,
    'word',v_word,
    'symbols',v_symbols,
    'sidewords',coalesce(v_sidewords,'[]'::jsonb),
    'sideword_total',coalesce(v_sideword_total,0),
    'leaderboard',coalesce(v_leaderboard,'[]'::jsonb)
  );
end;
$function$;

REVOKE ALL ON FUNCTION private.elementenpuzzle_weekly_review() FROM PUBLIC, anon;
GRANT USAGE ON SCHEMA private TO authenticated;
GRANT EXECUTE ON FUNCTION private.elementenpuzzle_weekly_review() TO authenticated;
CREATE OR REPLACE FUNCTION public.elementenpuzzle_weekly_review()
RETURNS jsonb LANGUAGE sql STABLE SECURITY INVOKER SET search_path TO ''
AS $$ SELECT private.elementenpuzzle_weekly_review(); $$;
REVOKE ALL ON FUNCTION public.elementenpuzzle_weekly_review() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.elementenpuzzle_weekly_review() TO authenticated;

