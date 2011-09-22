create or replace function setup_10_web()
returns setof text
as $test$
	begin
		perform web.clear_sessions();
		perform web.set_session_data('web-session-1', 'web-1-data', now() + interval '1 day');
		perform web.set_session_data('web-session-2', 'web-2-data', now() + interval '1 day');
		perform web.set_session_data('web-session-3', 'web-3-data', now() + interval '1 day');
		perform web.set_session_data('web-session-4', 'web-4-data', now() + interval '1 day');
	exception
		when invalid_schema_name then
			return;
		when undefined_function then 
			return;
	end;
$test$ language plpgsql;

create or replace function teardown_10_web()
returns setof text
as $test$
	begin
	exception
		when invalid_schema_name then
			return;
		when undefined_function then 
			return;
	end;
$test$ language plpgsql;

create or replace function test_web_schema()
returns setof text
as $$
	begin
		return next has_schema('web', 'There should be a web sessions schema.');
	end;
$$ language plpgsql;

create or replace function test_web_session_table()
returns setof text
as $$
	begin
		return next has_table('web', 'session', 'There should be a session table.');
	end;
$$ language plpgsql;

create or replace function test_web_session_id_exists()
returns setof text
as $$
	begin 
		return next has_column('web', 'session', 'sess_id', 'Needs to have a session id column.');
	end;
$$ language plpgsql;

create or replace function test_web_session_id_type()
returns setof text
as $$
	begin 
		return next col_type_is('web', 'session', 'sess_id', 'text', 'Session id is a string.');
	end; 
$$ language plpgsql;

create or replace function test_web_session_id_is_pk()
returns setof text
as $$
	begin
		return next col_is_pk('web', 'session', 'sess_id', 'The session id is the primary key');
	end;
$$ language plpgsql;

create or replace function test_web_session_data_exists()
returns setof text
as $$
	begin 
		return next has_column('web', 'session', 'sess_data', 'Needs to store the session data.');
	end;
$$ language plpgsql;

create or replace function test_web_session_data_type()
returns setof text
as $$
	begin 
		return next col_type_is('web', 'session', 'sess_data', 'text', 'Session data is text.');
	end; 
$$ language plpgsql;

create or replace function test_web_session_expiration_exists()
returns setof text
as $$
	begin 
		return next has_column('web', 'session', 'expiration', 'Needs a time limit on the session.');
	end;
$$ language plpgsql;

create or replace function test_web_session_expiration_type()
returns setof text
as $$
	begin 
		return next col_type_is('web', 'session', 'expiration', 'timestamp with time zone', 'expiration needs to be a timestamp.');
	end; 
$$ language plpgsql;

create or replace function test_web_session_expiration_default()
returns setof text
as $$
	begin
		return next col_default_is('web', 'session', 'expiration', $a$(now() + '1 day'::interval)$a$, 'Default expiration is on day.');
	end;
$$ language plpgsql;

create or replace function test_web_session_expiration_has_index()
returns setof text
as $$
	begin
		return next has_index('web', 'session', 'expire_idx', array['expiration'], 'Needs an index for the expiration column.');
	end;
$$ language plpgsql;

create or replace function test_web_function_setsessiondata_exists()
returns setof text
as $$
	begin 
		return next has_function('web', 'set_session_data', array['text', 'text', 'timestamp with time zone'], 'Needs a set session data function.');
		return next is_definer('web', 'set_session_data', array['text', 'text', 'timestamp with time zone'], 'Set session data should have definer security.');
		return next function_returns('web', 'set_session_data', array['text', 'text', 'timestamp with time zone'], 'void', 'Set session data should not return anything.');
	end;
$$ language plpgsql;

create or replace function test_web_function_setsessiondata_save_data()
returns setof text
as $$
	begin 
		perform web.set_session_data('web-new-session', 'new-data', null);
		return next results_eq(
			$a$select web.get_session_data('web-new-session')$a$,
			$a$values ('new-data')$a$,
			'The set_session_data should create a new session.');
	end;
$$ language plpgsql;

create or replace function test_web_function_setsessiondata_update_data()
returns setof text
as $$
	begin 
		perform web.set_session_data('web-session-1', 'new-data', now() + interval '1 day');
		return next results_eq(
			$a$select web.get_session_data('web-session-1')$a$,
			$a$values ('new-data')$a$,
			'The set_session_data should update a session.');
	end;
$$ language plpgsql;

create or replace function test_web_function_destroysession_exists()
returns setof text
as $$
	begin 
		return next has_function('web', 'destroy_session', array['text'], 'Needs to have a destroy function.');
		return next is_definer('web', 'destroy_session', array['text'], 'Session destroy should have definer security.');
		return next function_returns('web', 'destroy_session', array['text'], 'void', 'Session destroy should not return anything.');
	end;
$$ language plpgsql;

create or replace function test_web_function_destroysession_removes_data()
returns setof text
as $$
	begin
		perform web.destroy_session('web-session-1');
		return next is_empty(
			$a$select web.get_session_data('web-session-1')$a$,
			'Session destroy should delete the session');
	end;
$$ language plpgsql;

create or replace function test_web_function_getsessiondata_exists()
returns setof text
as $$
	begin 
		return next has_function('web', 'get_session_data', array['text'], 'Needs a get_session_data function.');
		return next is_definer('web', 'get_session_data', array['text'], 'Get session data should have definer security.');
		return next function_returns('web', 'get_session_data', array['text'], 'setof text', 'Get session data should not return anything.');
	end;
$$ language plpgsql;

create or replace function test_web_function_getsessiondata_data()
returns setof text
as $$
	begin 
		return next results_eq (
			$a$select web.get_session_data('web-session-1')$a$,
			$a$values ('web-1-data')$a$,
			'Get session data should retrieve the data from the session.');
	end;
$$ language plpgsql;

create or replace function test_web_function_getsessiondata_ignores_expired()
returns setof text
as $$
	begin
		perform web.set_session_data('web-session-1', 'web-1-data', now() - interval '1 day');
		return next is_empty(
			$a$select web.get_session_data('web-session-1')$a$,
			'Get session data ignores expired sessions.');
	end;
$$ language plpgsql;

create or replace function test_web_function_clearsessions_exists()
returns setof text
as $$
	begin 
		return next has_function('web', 'clear_sessions', 'Needs a clear function.');
		return next is_definer('web', 'clear_sessions', 'Clear sessions should have definer security.');
		return next function_returns('web', 'clear_sessions', 'void', 'Clear sessions data should not return anything.');
	end;
$$ language plpgsql;

create or replace function test_web_function_clearsessions_removes_data()
returns setof text
as $$
	begin
		perform web.clear_sessions();
		return next results_eq(
			'select web.count_sessions()',
			'values (0)',
			'Clear sessions should remove all sessions.');
	end;  
$$ language plpgsql;

create or replace function test_web_function_countsessions_exists()
returns setof text
as $$
	begin 
		return next has_function('web', 'count_sessions', 'Needs a count for the length function.'); 
		return next is_definer('web', 'count_sessions', 'Count sessions should have definer security.');
		return next function_returns('web', 'count_sessions', 'integer', 'Should return the number of active sessions.');
	end;
$$ language plpgsql;

create or replace function test_web_function_countsessions_returns_count()
returns setof text
as $$
	begin 
		return next results_eq(
			'select web.count_sessions()',
			'values (4)',
			'Count should return the number of sessions open.');
	end;
$$ language plpgsql;

create or replace function test_web_function_countsessions_ignores_expired()
returns setof text
as $$
	begin 
		perform web.set_session_data('web-session-3', 'web-3-data', now() - interval '1 day');
		return next results_eq(
			'select web.count_sessions()',
			'values (3)',
			'Count should ignore expired sessions.');
	end;
$$ language plpgsql;

create or replace function test_web_function_countsessions_counts_nulls()
returns setof text
as $$
	begin 
		perform web.set_session_data('web-session-3', 'web-3-data', null);
		return next results_eq(
			'select web.count_sessions()',
			'values (4)',
			'Count should include expire set to null.');
	end;
$$ language plpgsql;

create or replace function test_web_trigger_deleteexpired_exists()
returns setof text
as $$
	begin 
		return next trigger_is(
			'web',
			'session',
			'delete_expired_trig',
			'web',
			'remove_expired',
			'Needs a delete expired trigger.');
	end;
$$ language plpgsql;

create or replace function test_web_function_deleteexpired_exists()
returns setof text
as $$
	begin 
		return next has_function('web', 'remove_expired', 'Needs a function to delete expired records.');
		return next is_definer('web', 'remove_expired', 'Delete expired should have definer security.');
		return next function_returns('web', 'remove_expired', 'trigger', 'Delete expired data should return a trigger.');
	end;
$$ language plpgsql;

create or replace function test_web_function_deleteexpired_after_insert()
returns setof text
as $$
	begin 
		perform web.set_session_data('web-session-5', 'web-5-data', now() - interval '1 day');
		return next results_eq(
			'select cast(count(*) as int) from web.session',
			'values (4)',
			'Expired sessions should be deleted after insert.');
	end;
$$ language plpgsql;

create or replace function test_web_function_deleteexpired_after_update()
returns setof text
as $$
	begin 
		perform web.set_session_data('web-session-3', 'web-3-data', now() - interval '1 day');
		return next results_eq(
			'select cast(count(*) as int) from web.session',
			'values (3)',
			'Expired sessions should be deleted after insert.');
	end;
$$ language plpgsql;

create or replace function test_web_function_allids_is_removed()
returns setof text
as $$
	begin
		return next hasnt_function('web', 'all_session_ids', 'All ids is removed for security reasons.');
	end;
$$ language plpgsql;

create or replace function test_web_user_exists()
returns setof text
as $$
	begin 
		return next has_user('nodepg', 'Needs to have the nodepg user.');
	end;
$$ language plpgsql;

create or replace function failed_test( thetest text )
returns boolean
as $$
	declare 
		error_holder		text;
	begin
		select 
			runtests into error_holder
		from
			runtests(thetest)
		where
			runtests ~* '^not ok';
		return found;
	end;
$$ language plpgsql;

create or replace function correct_web()
returns setof text
as $funct$
	declare
		error_holder		text;
	begin
		if failed_test('test_web_schema') then
			create schema web;
			return next 'Created a schema';
		end if;
		if failed_test('test_web_session_table') then
			create table web.session();
			return next 'Created the session table.';
		end if;
		if failed_test('test_web_session_id_exists') then
			alter table web.session 
				add column sess_id text;
			return next 'Added sess_id column.';
		end if;
		if failed_test('test_web_session_id_type') then 
			alter table web.session
				alter column sess_id type text;
			return next 'Changed sess_id to type text.';
		end if;
		if failed_test('test_web_session_id_is_pk') then 
			alter table web.session
				add primary key (sess_id);
			return next 'Made sess_id the primary key.';
		end if;
		if failed_test('test_web_session_data_exists') then
			alter table web.session 
				add column sess_data text;
			return next 'Added sess_data column.';
		end if;
		if failed_test('test_web_session_data_type') then 
			alter table web.session
				alter column sess_data type text;
			return next 'Changed sess_data to type text.';
		end if;
		if failed_test('test_web_session_expiration_exists') then
			alter table web.session 
				add column expiration timestamp with time zone;
			return next 'Added expiration column.';
		end if;
		if failed_test('test_web_session_data_type') then 
			alter table web.session
				alter column expiration type timestamp with time zone;
			return next 'Changed expiration to type timestamp.';
		end if;
		if failed_test('test_web_session_expiration_default') then
			alter table web.session
				alter column expiration set default now() + interval '1 day';
			return next 'Added expiration default.';
		end if;
		if failed_test('test_web_session_expiration_has_index') then
			create index expire_idx on web.session (expiration);
			return next 'Created expiration index.';
		end if;
		
		if failed_test('test_web_function_allids_is_removed') then
			drop function web.all_session_ids();
			return next 'Removed all ids for security reasons.';
		end if;
		
		create or replace function web.valid_sessions()
		returns setof web.session as $$
			begin
				return query select * from web.session
					where expiration > now() 
						or expiration is null;
			end;
		$$ language plpgsql security definer
		set search_path = web, pg_temp;
		
		create or replace function web.set_session_data(
			sessid text, 
			sessdata text, 
			expire timestamp with time zone) 
		returns void as $$
			begin
				loop
					update web.session 
						set sess_data = sessdata, 
							expiration = expire 
						where sess_id = sessid;
					if found then
						return;
					end if;
					begin
						insert into web.session (sess_id, sess_data, expiration) 
							values (sessid, sessdata, expire);
						return;
					exception
						when unique_violation then
							-- do nothing.
					end;
				end loop;
			end;
		$$ language plpgsql security definer
		set search_path = web, pg_temp;
		return next 'Created function web.set_session_data';
		
		create or replace function web.destroy_session(sessid text)
		returns void as $$
			begin
				delete from web.session where sess_id = sessid;
			end;
		$$ language plpgsql security definer
		set search_path = web, pg_temp;
		return next 'Created function web.destroy_session.';
		
		create or replace function web.get_session_data(sessid text)
		returns setof text as $$
			begin
				return query select sess_data 
					from web.valid_sessions()
					where sess_id = sessid;
			end;
		$$ language plpgsql security definer
		set search_path = web, pg_temp;
		return next 'Created function web.get_session.';
		
		create or replace function web.clear_sessions()
		returns void as $$
			begin 
				delete from web.session;
			end;
		$$ language plpgsql security definer
		set search_path = web, pg_temp;		
		return next 'Created function web.clear_sessions.';

		create or replace function web.count_sessions()
		returns int as $$
			declare
				thecount int := 0;
			begin
				select count(*) into thecount
					from web.valid_sessions();
				return thecount;
			end;
		$$ language plpgsql security definer
		set search_path = web, pg_temp;
		return next 'Created function web.count_sessions.';

		drop trigger if exists delete_expired_trig on web.session;

		create or replace function web.remove_expired()
		returns trigger as $$
			begin
				delete from web.session where expiration < now();
				return null;
			end;
		$$ language plpgsql security definer
		set search_path = web, pg_temp;
		return next 'Created trigger function web.delete_expired.';
		
		create trigger delete_expired_trig
			after insert or update
			on web.session
			execute procedure web.remove_expired();
		return next 'Created trigger delete_expired on web.session.';
		
		if failed_test('test_web_user_exists') then 
			create user nodepg with password 'password';
			return next 'Created user nodepg';
		end if;
		
		revoke all on function 
			web.valid_sessions(),
			web.set_session_data(
				sessid text, 
				sessdata text, 
				expire timestamp with time zone),
			web.destroy_session(sessid text),
			web.get_session_data(sessid text),
			web.clear_sessions(),
			web.count_sessions(),
			web.remove_expired()
		from public;
		
		grant execute on function 
			web.set_session_data(
				sessid text, 
				sessdata text, 
				expire timestamp with time zone),
			web.destroy_session(sessid text),
			web.get_session_data(sessid text),
			web.clear_sessions(),
			web.count_sessions()
		to nodepg;
		
		grant usage on schema web to nodepg;
		
		return next 'Permissions set.';
	end;
$funct$ language plpgsql;
