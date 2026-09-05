-- Zusaetzliches Sonntagsraetsel fuer angemeldete Spieler.
-- Das normale Tagesraetsel bleibt unveraendert und auf maximal 6 Symbole begrenzt.

create table if not exists public.elementenpuzzle_weekly_puzzles (
  sunday_date date primary key,
  word text not null,
  symbols text[] not null check (cardinality(symbols) between 7 and 10),
  choices text[] not null check (cardinality(choices) between 1 and 30),
  source_word_id bigint references public.elementenpuzzle_word_bank(id),
  sideword_count integer not null check (sideword_count >= 8),
  created_at timestamptz not null default clock_timestamp(),
  check (extract(dow from sunday_date) = 0)
);

create table if not exists public.elementenpuzzle_weekly_attempts (
  sunday_date date not null references public.elementenpuzzle_weekly_puzzles(sunday_date),
  user_id uuid not null references auth.users(id) on delete cascade,
  started_at timestamptz not null,
  solved_at timestamptz,
  elapsed_ms bigint check (elapsed_ms is null or elapsed_ms >= 0),
  guesses integer not null default 0 check (guesses >= 0),
  confirmed_symbols text[] not null default array[]::text[],
  last_guess_symbols text[],
  primary key (sunday_date, user_id)
);

create index if not exists elementenpuzzle_weekly_attempts_user_idx
  on public.elementenpuzzle_weekly_attempts(user_id);
create index if not exists elementenpuzzle_weekly_puzzles_source_idx
  on public.elementenpuzzle_weekly_puzzles(source_word_id);

alter table public.elementenpuzzle_weekly_puzzles enable row level security;
alter table public.elementenpuzzle_weekly_attempts enable row level security;
revoke all on public.elementenpuzzle_weekly_puzzles from anon, authenticated;
revoke all on public.elementenpuzzle_weekly_attempts from anon, authenticated;

create or replace function public.elementenpuzzle_weekly_ensure(p_sunday date)
returns table(sunday_date date, word text, symbols text[], choices text[], sideword_count integer)
language plpgsql
security definer
set search_path = public, auth
as $function$
declare
  v_uid uuid := auth.uid();
  r record;
  v_choices text[];
  v_count integer;
begin
  if v_uid is null then raise exception 'Anmeldung erforderlich'; end if;
  if p_sunday is null or extract(dow from p_sunday) <> 0 then
    raise exception 'Das Zusatzraetsel ist nur sonntags verfuegbar';
  end if;

  perform pg_advisory_xact_lock(hashtext('elementenpuzzle-weekly:' || p_sunday::text));

  if not exists (
    select 1 from public.elementenpuzzle_weekly_puzzles w where w.sunday_date=p_sunday
  ) then
    for r in
      select b.id,b.word,b.symbols
      from public.elementenpuzzle_word_bank b
      where b.active
        and cardinality(b.symbols) between 7 and 10
        and not exists (
          select 1 from public.elementenpuzzle_daily_puzzles d
          where lower(d.word)=lower(b.word) and d.publication_status='approved'
        )
        and not exists (
          select 1 from public.elementenpuzzle_weekly_puzzles old
          where lower(old.word)=lower(b.word)
        )
      order by md5(p_sunday::text || ':weekly-v1:' || b.id::text)
    loop
      v_choices := public.elementenpuzzle_smart_choices(p_sunday,r.symbols);
      v_count := public.elementenpuzzle_sideword_count(r.word,r.symbols,v_choices);
      if v_count >= 8 then
        insert into public.elementenpuzzle_weekly_puzzles(
          sunday_date,word,symbols,choices,source_word_id,sideword_count
        ) values (p_sunday,r.word,r.symbols,v_choices,r.id,v_count);
        exit;
      end if;
    end loop;
    if not exists (
      select 1 from public.elementenpuzzle_weekly_puzzles w where w.sunday_date=p_sunday
    ) then
      raise exception 'Kein geeignetes langes Sonntagswort verfuegbar';
    end if;
  end if;

  return query
  select w.sunday_date,w.word,w.symbols,w.choices,w.sideword_count
  from public.elementenpuzzle_weekly_puzzles w where w.sunday_date=p_sunday;
end;
$function$;

create or replace function public.elementenpuzzle_weekly_status()
returns table(available boolean, sunday_date date, started boolean, element_count integer,
              choices text[], started_at timestamptz, solved boolean, elapsed_ms bigint,
              solved_word text, solved_symbols text[], guesses integer)
language plpgsql
security definer
set search_path = public, auth
as $function$
declare
  v_uid uuid := auth.uid();
  v_date date := public.elementenpuzzle_today();
  v_puzzle public.elementenpuzzle_weekly_puzzles%rowtype;
  v_attempt public.elementenpuzzle_weekly_attempts%rowtype;
  v_started boolean := false;
begin
  if v_uid is null then raise exception 'Anmeldung erforderlich'; end if;
  if extract(dow from v_date) <> 0 then
    return query select false,null::date,false,null::integer,null::text[],null::timestamptz,
      false,null::bigint,null::text,null::text[],0;
    return;
  end if;
  perform public.elementenpuzzle_weekly_ensure(v_date);
  select w.* into v_puzzle from public.elementenpuzzle_weekly_puzzles w where w.sunday_date=v_date;
  select a.* into v_attempt from public.elementenpuzzle_weekly_attempts a
    where a.sunday_date=v_date and a.user_id=v_uid;
  v_started := found;
  return query select true,v_date,v_started,cardinality(v_puzzle.symbols),
    case when v_started then v_puzzle.choices else null::text[] end,
    v_attempt.started_at,(v_attempt.solved_at is not null),v_attempt.elapsed_ms,
    case when v_attempt.solved_at is not null then v_puzzle.word else null end,
    case when v_attempt.solved_at is not null then v_puzzle.symbols else null end,
    coalesce(v_attempt.guesses,0);
end;
$function$;

create or replace function public.elementenpuzzle_weekly_start()
returns table(puzzle_date date, element_count integer, choices text[], started_at timestamptz,
              solved boolean, elapsed_ms bigint, solved_word text, solved_symbols text[], guesses integer)
language plpgsql
security definer
set search_path = public, auth
as $function$
declare
  v_uid uuid := auth.uid();
  v_date date := public.elementenpuzzle_today();
  v_puzzle public.elementenpuzzle_weekly_puzzles%rowtype;
  v_attempt public.elementenpuzzle_weekly_attempts%rowtype;
  v_delay integer;
begin
  if v_uid is null then raise exception 'Anmeldung erforderlich'; end if;
  if extract(dow from v_date) <> 0 then raise exception 'Das Zusatzraetsel ist nur sonntags verfuegbar'; end if;
  perform public.elementenpuzzle_weekly_ensure(v_date);
  select w.* into v_puzzle from public.elementenpuzzle_weekly_puzzles w where w.sunday_date=v_date;
  v_delay := 800 + greatest(cardinality(v_puzzle.choices)-1,0)*220 + 220;
  insert into public.elementenpuzzle_weekly_attempts(sunday_date,user_id,started_at)
  values(v_date,v_uid,clock_timestamp()+(v_delay*interval '1 millisecond')) on conflict do nothing;
  select a.* into v_attempt from public.elementenpuzzle_weekly_attempts a
    where a.sunday_date=v_date and a.user_id=v_uid;
  return query select v_date,cardinality(v_puzzle.symbols),v_puzzle.choices,v_attempt.started_at,
    (v_attempt.solved_at is not null),v_attempt.elapsed_ms,
    case when v_attempt.solved_at is not null then v_puzzle.word else null end,
    case when v_attempt.solved_at is not null then v_puzzle.symbols else null end,v_attempt.guesses;
end;
$function$;

create or replace function public.elementenpuzzle_weekly_submit(p_symbols text[])
returns table(correct boolean, solved_word text, solved_symbols text[], elapsed_ms bigint, guesses integer, rank integer)
language plpgsql
security definer
set search_path = public, auth
as $function$
declare
  v_uid uuid := auth.uid(); v_date date := public.elementenpuzzle_today();
  v_puzzle public.elementenpuzzle_weekly_puzzles%rowtype;
  v_attempt public.elementenpuzzle_weekly_attempts%rowtype;
  v_now timestamptz; v_elapsed bigint; v_rank integer;
begin
  if v_uid is null then raise exception 'Anmeldung erforderlich'; end if;
  if extract(dow from v_date) <> 0 then raise exception 'Das Zusatzraetsel ist nur sonntags verfuegbar'; end if;
  select w.* into v_puzzle from public.elementenpuzzle_weekly_puzzles w where w.sunday_date=v_date;
  select a.* into v_attempt from public.elementenpuzzle_weekly_attempts a
    where a.sunday_date=v_date and a.user_id=v_uid for update;
  if not found then raise exception 'Das Sonntagsraetsel wurde noch nicht gestartet'; end if;
  if cardinality(p_symbols) <> cardinality(v_puzzle.symbols) then
    raise exception 'Es muessen genau % Elementsymbole gewaehlt werden',cardinality(v_puzzle.symbols);
  end if;
  if exists(select 1 from unnest(p_symbols) s(sym) where not(s.sym=any(v_puzzle.choices))) then
    raise exception 'Ungueltiges Elementsymbol';
  end if;
  if v_attempt.solved_at is null then
    update public.elementenpuzzle_weekly_attempts a set guesses=a.guesses+1,last_guess_symbols=p_symbols
    where a.sunday_date=v_date and a.user_id=v_uid returning a.* into v_attempt;
    if lower(array_to_string(p_symbols,''))=lower(v_puzzle.word) then
      v_now:=clock_timestamp();
      v_elapsed:=greatest(0,floor(extract(epoch from(v_now-v_attempt.started_at))*1000)::bigint);
      update public.elementenpuzzle_weekly_attempts a set solved_at=v_now,elapsed_ms=v_elapsed
      where a.sunday_date=v_date and a.user_id=v_uid returning a.* into v_attempt;
    end if;
  end if;
  if v_attempt.solved_at is not null then
    select 1+count(*)::integer into v_rank from public.elementenpuzzle_weekly_attempts x
      where x.sunday_date=v_date and x.solved_at is not null and x.elapsed_ms<v_attempt.elapsed_ms;
    return query select true,v_puzzle.word,v_puzzle.symbols,v_attempt.elapsed_ms,v_attempt.guesses,v_rank;
  else
    return query select false,null::text,null::text[],null::bigint,v_attempt.guesses,null::integer;
  end if;
end;
$function$;

create or replace function public.elementenpuzzle_weekly_check_word_feedback(p_symbols text[])
returns table(valid_word boolean, matched_word text, shared_symbols text[], confirmed_symbols text[], feedback text[])
language plpgsql
security definer
set search_path = public, auth
as $function$
declare
  v_uid uuid:=auth.uid(); v_date date:=public.elementenpuzzle_today();
  v_puzzle public.elementenpuzzle_weekly_puzzles%rowtype;
  v_attempt public.elementenpuzzle_weekly_attempts%rowtype;
  v_word text; v_feedback text[]; v_remaining text[]; v_shared text[]:=array[]::text[];
  v_confirmed text[]:=array[]::text[]; i integer; j integer; n integer;
begin
  if v_uid is null then raise exception 'Anmeldung erforderlich'; end if;
  if extract(dow from v_date)<>0 then raise exception 'Das Zusatzraetsel ist nur sonntags verfuegbar'; end if;
  select w.* into v_puzzle from public.elementenpuzzle_weekly_puzzles w where w.sunday_date=v_date;
  select a.* into v_attempt from public.elementenpuzzle_weekly_attempts a
    where a.sunday_date=v_date and a.user_id=v_uid for update;
  if not found then raise exception 'Das Sonntagsraetsel wurde noch nicht gestartet'; end if;
  if v_attempt.last_guess_symbols is distinct from p_symbols then raise exception 'Bitte das Wort zuerst absenden'; end if;
  v_word:=lower(array_to_string(p_symbols,''));
  if not exists(select 1 from public.elementenpuzzle_german_words g where g.word=v_word and g.active) then
    return query select false,null::text,array[]::text[],v_attempt.confirmed_symbols,array[]::text[]; return;
  end if;
  n:=cardinality(v_puzzle.symbols); v_feedback:=array_fill('gray'::text,array[n]); v_remaining:=v_puzzle.symbols;
  for i in 1..n loop if p_symbols[i]=v_puzzle.symbols[i] then v_feedback[i]:='green'; v_remaining[i]:=null; end if; end loop;
  for i in 1..n loop if v_feedback[i]<>'green' then for j in 1..n loop
    if v_remaining[j] is not null and v_remaining[j]=p_symbols[i] then v_feedback[i]:='yellow';v_remaining[j]:=null;exit;end if;
  end loop; end if; end loop;
  select coalesce(array_agg(sym order by pos),array[]::text[]) into v_shared
  from (select s.sym,min(s.pos) pos from unnest(p_symbols) with ordinality s(sym,pos)
    join unnest(v_feedback) with ordinality f(state,pos2) on f.pos2=s.pos
    where f.state in('green','yellow') group by s.sym) q;
  select coalesce(array_agg(sym order by pos),array[]::text[]) into v_confirmed
  from (select s.sym,min(s.pos) pos from unnest(v_attempt.confirmed_symbols||v_shared) with ordinality s(sym,pos) group by s.sym) q;
  update public.elementenpuzzle_weekly_attempts a set confirmed_symbols=v_confirmed
    where a.sunday_date=v_date and a.user_id=v_uid;
  return query select true,v_word,v_shared,v_confirmed,v_feedback;
end;
$function$;

create or replace function public.elementenpuzzle_weekly_leaderboard()
returns table(rank bigint,username text,elapsed_ms bigint,guesses integer,solved_at timestamptz)
language sql stable security definer set search_path=public,auth
as $function$
select rank() over(order by a.elapsed_ms,a.solved_at),
  coalesce(nullif(u.raw_user_meta_data->>'username',''),'Spieler-'||left(a.user_id::text,4)),
  a.elapsed_ms,a.guesses,a.solved_at
from public.elementenpuzzle_weekly_attempts a join auth.users u on u.id=a.user_id
where a.sunday_date=public.elementenpuzzle_today() and extract(dow from public.elementenpuzzle_today())=0
  and a.solved_at is not null order by a.elapsed_ms,a.solved_at limit 50
$function$;

revoke execute on function public.elementenpuzzle_weekly_ensure(date) from public,anon,authenticated;
revoke execute on function public.elementenpuzzle_weekly_status() from public,anon;
revoke execute on function public.elementenpuzzle_weekly_start() from public,anon;
revoke execute on function public.elementenpuzzle_weekly_submit(text[]) from public,anon;
revoke execute on function public.elementenpuzzle_weekly_check_word_feedback(text[]) from public,anon;
revoke execute on function public.elementenpuzzle_weekly_leaderboard() from public,anon;
grant execute on function public.elementenpuzzle_weekly_status() to authenticated;
grant execute on function public.elementenpuzzle_weekly_start() to authenticated;
grant execute on function public.elementenpuzzle_weekly_submit(text[]) to authenticated;
grant execute on function public.elementenpuzzle_weekly_check_word_feedback(text[]) to authenticated;
grant execute on function public.elementenpuzzle_weekly_leaderboard() to authenticated;
