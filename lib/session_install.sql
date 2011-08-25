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

create or replace function correct_web()
returns setof text
as $$
	declare
		error_holder		text;
	begin
		prepare db_test (text) as 
			select 
				runtests
			from
				runtests($1)
			where
				runtests ~* '^not ok';
		-- web schema
		execute db_test('test_web_schema');
		if found then
			create schema web;
			return next 'Created a schema';
		end if;
				
		/*
		-- Schema
		select 
			runtests into error_holder
		from
			runtests('test_web_schema')
		where
			runtests ~* '^not ok';
		if found then
			create schema web;
			return next 'Created a schema';
		end if;
		-- session table
		select 
			runtests into error_holder
		from
			runtests('test_web_session_table')
		where
			runtests ~* '^not ok';
		if found then
			create table web.session();
			return next 'Created the session table.';
		end if;
		*/
	end;
$$ language plpgsql;

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