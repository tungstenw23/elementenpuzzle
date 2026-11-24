-- Deploy before publishing index.html so both old and new tabs can call the RPCs.
begin;

CREATE OR REPLACE FUNCTION public.elementenpuzzle_submit(p_symbols text[], p_date date)
 RETURNS TABLE(correct boolean, solved_word text, solved_symbols text[], elapsed_ms bigint, guesses integer, rank integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare
  v_uid uuid := auth.uid();
  v_date date := p_date;
  v_word text;
  v_symbols text[];
  v_choices text[];
  v_attempt public.elementenpuzzle_attempts%rowtype;
  v_now timestamptz;
  v_elapsed bigint;
  v_rank integer;
  v_guess_word text;
begin
  if v_uid is null then
    raise exception 'Anmeldung erforderlich';
  end if;

  if p_date is null or not (p_date between public.elementenpuzzle_today() - 1 and public.elementenpuzzle_today()) then
    raise exception 'Dieses Tagesraetsel ist nicht mehr spielbar';
  end if;

  select p.word, p.symbols
    into v_word, v_symbols
  from public.elementenpuzzle_puzzle_for_date(v_date) as p;

  select ep.*
    into v_attempt
  from public.elementenpuzzle_attempts as ep
  where ep.puzzle_date = v_date
    and ep.user_id = v_uid
  for update;

  if not found then
    raise exception 'Das Tagesraetsel wurde noch nicht gestartet';
  end if;

  if v_attempt.solved_at is not null then
    select 1 + count(*)::integer
      into v_rank
    from public.elementenpuzzle_attempts as x
    where x.puzzle_date = v_date
      and (x.solved_at at time zone 'Europe/Berlin')::date = v_date
      and x.elapsed_ms < v_attempt.elapsed_ms;

    return query
    select true, v_word, v_symbols, v_attempt.elapsed_ms, v_attempt.guesses,
      case when (v_attempt.solved_at at time zone 'Europe/Berlin')::date = v_date then v_rank end;
    return;
  end if;

  if cardinality(p_symbols) <> cardinality(v_symbols) then
    raise exception 'Es muessen genau % Elementsymbole gewaehlt werden', cardinality(v_symbols);
  end if;

  v_choices := public.elementenpuzzle_choices_for_date(v_date, v_symbols);

  if exists (
    select 1
    from unnest(p_symbols) as s(sym)
    where not (s.sym = any(v_choices))
  ) then
    raise exception 'Ungueltiges Elementsymbol';
  end if;

  update public.elementenpuzzle_attempts as ep
  set guesses = ep.guesses + 1,
      last_guess_symbols = p_symbols,
      last_guess_at = clock_timestamp()
  where ep.puzzle_date = v_date
    and ep.user_id = v_uid
  returning ep.* into v_attempt;

  v_guess_word := lower(array_to_string(p_symbols,''));

  if v_guess_word = lower(v_word) then
    v_now := clock_timestamp();
    v_elapsed := greatest(
      0,
      floor(extract(epoch from (v_now - v_attempt.started_at)) * 1000)::bigint
    );

    update public.elementenpuzzle_attempts as ep
    set solved_at = v_now,
        elapsed_ms = v_elapsed
    where ep.puzzle_date = v_date
      and ep.user_id = v_uid
    returning ep.* into v_attempt;

    select 1 + count(*)::integer
      into v_rank
    from public.elementenpuzzle_attempts as x
    where x.puzzle_date = v_date
      and (x.solved_at at time zone 'Europe/Berlin')::date = v_date
      and x.elapsed_ms < v_elapsed;

    return query
    select true, v_word, v_symbols, v_elapsed, v_attempt.guesses,
      case when (v_now at time zone 'Europe/Berlin')::date = v_date then v_rank end;
  else
    return query
    select false, null::text, null::text[], null::bigint, v_attempt.guesses, null::integer;
  end if;
end;
$function$;
revoke all on function public.elementenpuzzle_submit(text[], date) from public, anon;
grant execute on function public.elementenpuzzle_submit(text[], date) to authenticated;

CREATE OR REPLACE FUNCTION public.elementenpuzzle_submit(p_symbols text[])
 RETURNS TABLE(correct boolean, solved_word text, solved_symbols text[], elapsed_ms bigint, guesses integer, rank integer)
 LANGUAGE sql
 SECURITY INVOKER
 SET search_path TO ''
AS $function$
  select * from public.elementenpuzzle_submit(p_symbols, public.elementenpuzzle_active_daily_date());
$function$;

CREATE OR REPLACE FUNCTION public.elementenpuzzle_check_word_feedback(p_symbols text[], p_date date)
 RETURNS TABLE(valid_word boolean, matched_word text, shared_symbols text[], confirmed_symbols text[], feedback text[])
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare
  v_uid uuid := auth.uid();
  v_date date := p_date;
  v_target_word text;
  v_target_symbols text[];
  v_choices text[];
  v_guess_word text;
  v_original text;
  v_shared text[] := ARRAY[]::text[];
  v_confirmed text[] := ARRAY[]::text[];
  v_feedback text[];
  v_remaining text[];
  v_attempt public.elementenpuzzle_attempts%rowtype;
  i integer;
  j integer;
  n integer;
begin
  if v_uid is null then
    raise exception 'Anmeldung erforderlich';
  end if;

  if p_date is null or not (p_date between public.elementenpuzzle_today() - 1 and public.elementenpuzzle_today()) then
    raise exception 'Dieses Tagesraetsel ist nicht mehr spielbar';
  end if;

  select p.word, p.symbols
    into v_target_word, v_target_symbols
  from public.elementenpuzzle_puzzle_for_date(v_date) as p;

  select ep.*
    into v_attempt
  from public.elementenpuzzle_attempts as ep
  where ep.puzzle_date = v_date
    and ep.user_id = v_uid
  for update;

  if not found then
    raise exception 'Das Tagesraetsel wurde noch nicht gestartet';
  end if;

  if cardinality(p_symbols) <> cardinality(v_target_symbols) then
    raise exception 'Es muessen genau % Elementsymbole gewaehlt werden', cardinality(v_target_symbols);
  end if;

  if v_attempt.solved_at is null
     and v_attempt.last_guess_symbols is distinct from p_symbols then
    raise exception 'Bitte das Wort zuerst mit Wort pruefen absenden';
  end if;

  if v_attempt.solved_at is null then
    v_choices := public.elementenpuzzle_choices_for_date(v_date, v_target_symbols);
  else
    v_choices := public.elementenpuzzle_smart_choices(v_date, v_target_symbols);
  end if;

  if exists (
    select 1 from unnest(p_symbols) as s(sym)
    where not (s.sym = any(v_choices))
  ) then
    raise exception 'Ungueltiges Elementsymbol';
  end if;

  v_guess_word := lower(array_to_string(p_symbols,''));

  -- Einheitliche Wörterbuchprüfung: dieselbe große deutsche Worttabelle
  -- verwenden wie elementenpuzzle_check_word.
  select d.word
    into v_original
  from public.elementenpuzzle_german_words d
  where d.active
    and d.word = v_guess_word
  limit 1;

  if not found then
    return query
    select false, null::text, ARRAY[]::text[],
           coalesce(v_attempt.confirmed_symbols, ARRAY[]::text[]),
           ARRAY[]::text[];
    return;
  end if;

  n := cardinality(v_target_symbols);
  v_feedback := array_fill('gray'::text, ARRAY[n]);
  v_remaining := v_target_symbols;

  for i in 1..n loop
    if p_symbols[i] = v_target_symbols[i] then
      v_feedback[i] := 'green';
      v_remaining[i] := null;
    end if;
  end loop;

  for i in 1..n loop
    if v_feedback[i] <> 'green' then
      for j in 1..n loop
        if v_remaining[j] is not null and v_remaining[j] = p_symbols[i] then
          v_feedback[i] := 'yellow';
          v_remaining[j] := null;
          exit;
        end if;
      end loop;
    end if;
  end loop;

  select coalesce(array_agg(sym order by first_pos), ARRAY[]::text[])
    into v_shared
  from (
    select s.sym, min(s.pos) as first_pos
    from unnest(p_symbols) with ordinality as s(sym,pos)
    join unnest(v_feedback) with ordinality as f(state,pos2)
      on f.pos2 = s.pos
    where f.state in ('green','yellow')
    group by s.sym
  ) q;

  if v_attempt.solved_at is null and cardinality(v_shared) > 0 then
    select coalesce(array_agg(sym order by first_pos), ARRAY[]::text[])
      into v_confirmed
    from (
      select s.sym, min(s.pos) as first_pos
      from unnest(coalesce(v_attempt.confirmed_symbols, ARRAY[]::text[]) || v_shared)
           with ordinality as s(sym,pos)
      group by s.sym
    ) q;

    update public.elementenpuzzle_attempts as ep
    set confirmed_symbols = v_confirmed
    where ep.puzzle_date = v_date
      and ep.user_id = v_uid;
  else
    v_confirmed := coalesce(v_attempt.confirmed_symbols, ARRAY[]::text[]);
  end if;

  if v_attempt.solved_at is null then
    insert into public.elementenpuzzle_guess_history(
      puzzle_date,user_id,guess_no,matched_word,symbols,feedback
    )
    values(
      v_date,v_uid,v_attempt.guesses,coalesce(v_original,v_guess_word),p_symbols,v_feedback
    )
    on conflict (puzzle_date,user_id,guess_no)
    do update set
      matched_word = excluded.matched_word,
      symbols = excluded.symbols,
      feedback = excluded.feedback;
  end if;

  return query
  select true, coalesce(v_original, v_guess_word), v_shared, v_confirmed, v_feedback;
end;
$function$;
revoke all on function public.elementenpuzzle_check_word_feedback(text[], date) from public, anon;
grant execute on function public.elementenpuzzle_check_word_feedback(text[], date) to authenticated;

CREATE OR REPLACE FUNCTION public.elementenpuzzle_check_word_feedback(p_symbols text[])
 RETURNS TABLE(valid_word boolean, matched_word text, shared_symbols text[], confirmed_symbols text[], feedback text[])
 LANGUAGE sql
 SECURITY INVOKER
 SET search_path TO ''
AS $function$
  select * from public.elementenpuzzle_check_word_feedback(p_symbols, public.elementenpuzzle_active_daily_date());
$function$;

CREATE OR REPLACE FUNCTION public.elementenpuzzle_confirmed_symbols(p_date date)
 RETURNS TABLE(confirmed_symbols text[])
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare
  v_uid uuid := auth.uid();
  v_date date := p_date;
  v_confirmed text[];
begin
  if v_uid is null then
    raise exception 'Anmeldung erforderlich';
  end if;

  if p_date is null or not (p_date between public.elementenpuzzle_today() - 1 and public.elementenpuzzle_today()) then
    raise exception 'Dieses Tagesraetsel ist nicht mehr spielbar';
  end if;

  select ep.confirmed_symbols
    into v_confirmed
  from public.elementenpuzzle_attempts as ep
  where ep.puzzle_date = v_date
    and ep.user_id = v_uid;

  return query select coalesce(v_confirmed, ARRAY[]::text[]);
end;
$function$;
revoke all on function public.elementenpuzzle_confirmed_symbols(date) from public, anon;
grant execute on function public.elementenpuzzle_confirmed_symbols(date) to authenticated;

CREATE OR REPLACE FUNCTION public.elementenpuzzle_confirmed_symbols()
 RETURNS TABLE(confirmed_symbols text[])
 LANGUAGE sql
 SECURITY INVOKER
 SET search_path TO ''
AS $function$
  select * from public.elementenpuzzle_confirmed_symbols(public.elementenpuzzle_active_daily_date());
$function$;

CREATE OR REPLACE FUNCTION public.elementenpuzzle_feedback_history(p_date date)
 RETURNS TABLE(guess_no integer, matched_word text, symbols text[], feedback text[])
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
  select h.guess_no, h.matched_word, h.symbols, h.feedback
  from public.elementenpuzzle_guess_history h
  where h.puzzle_date = p_date
    and p_date between public.elementenpuzzle_today() - 1 and public.elementenpuzzle_today()
    and h.user_id = auth.uid()
  order by h.guess_no, h.id
$function$;
revoke all on function public.elementenpuzzle_feedback_history(date) from public, anon;
grant execute on function public.elementenpuzzle_feedback_history(date) to authenticated;

CREATE OR REPLACE FUNCTION public.elementenpuzzle_feedback_history()
 RETURNS TABLE(guess_no integer, matched_word text, symbols text[], feedback text[])
 LANGUAGE sql
 SECURITY INVOKER
 SET search_path TO ''
AS $function$
  select * from public.elementenpuzzle_feedback_history(public.elementenpuzzle_active_daily_date());
$function$;

-- The previous day's solution is visible after midnight in Berlin.
CREATE OR REPLACE FUNCTION public.elementenpuzzle_yesterday_review()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare
  v_date date := public.elementenpuzzle_today() - 1;
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

  -- Always derive yesterday on the server, never accept a user-supplied date.
  select d.word,d.symbols,c.choices
    into v_word,v_symbols,v_choices
  from public.elementenpuzzle_daily_puzzles d
  join public.elementenpuzzle_daily_choices c
    on c.puzzle_date=d.puzzle_date
  where d.puzzle_date=v_date and d.publication_status='approved';

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
    from public.elementenpuzzle_attempts a
    join auth.users u on u.id=a.user_id
    where a.puzzle_date=v_date
      and (a.solved_at at time zone 'Europe/Berlin')::date = v_date
      and a.elapsed_ms is not null
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'rank',s.rank,'username',s.username,
    'elapsed_ms',s.elapsed_ms,'guesses',s.guesses
  ) order by s.rank),'[]'::jsonb)
  into v_leaderboard
  from (
    select * from standings order by rank limit 50
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

commit;
