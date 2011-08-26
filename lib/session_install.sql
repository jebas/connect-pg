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
		/*
		create or replace function web.testing()
		returns text
		as $$
			begin
				return 'This worked.';
			end;
		$$ language plpgsql;
		*/
	end;
$funct$ language plpgsql;

/*
-- This installs the table and functions for connect-pg.

create schema web;

create table web.session (
	sess_id text primary key,
	sess_data text,
	expiration timestamp with time zone default now() + interval '1 day'
);

create index expire_idx on web.session (expiration);

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
$$ language plpgsql security definer;

create or replace function web.get_session_data(sessid text)
returns text as $$
	declare
		sessdata text;
	begin
		select sess_data into sessdata 
			from web.session 
			where sess_id = sessid 
				and (expiration > now() or expiration isnull);
		return sessdata;
	end;
$$ language plpgsql security definer;

create or replace function web.destroy_session(sessid text)
returns void as $$
	begin
		delete from web.session where sess_id = sessid;
		return;
	end;
$$ language plpgsql security definer;

create or replace function web.clear_sessions()
returns void as $$
	begin
		delete from web.session;
		return;
	end;
$$ language plpgsql security definer;

create or replace function web.count_sessions()
returns int as $$
	declare
		thecount int := 0;
	begin
		select count(*) into thecount from web.session where expiration > now() or expiration isnull;
		return thecount;
	end;
$$ language plpgsql security definer;

create or replace function web.all_session_ids()
returns setof text as $$
	begin
		return query select sess_id from web.session where expiration > now() or expiration isnull;
		return;
	end;
$$ language plpgsql security definer;

create or replace function web.remove_expired()
returns trigger as $$
	begin
		delete from web.session where expiration < now();
		return null;
	end;
$$ language plpgsql security definer;

create trigger delete_expired_trig
	after insert or update
	on web.session
	execute procedure web.remove_expired();
*/