-- This installs the table and functions for connect-pg.

create table connect_session (
	sess_id text primary key,
	sess_data text,
	expiration timestamp with time zone default now() + interval '1 day'
);

create index sess_expiration on connect_session (expiration);

create or replace function set_session_data(
	sessid text, 
	sessdata text, 
	expire timestamp with time zone) 
returns void as $$
	begin
		loop
			update connect_session 
				set sess_data = sessdata, 
					expiration = expire 
				where sess_id = sessid;
			if found then
				return;
			end if;
			begin
				insert into connect_session (sess_id, sess_data, expiration) 
					values (sessid, sessdata, expire);
				return;
			exception
				when unique_violation then
					-- do nothing.
			end;
		end loop;
	end;
$$ language plpgsql;

create or replace function get_session_data(sessid text)
returns text as $$
	declare
		sessdata text;
	begin
		select sess_data into sessdata 
			from connect_session 
			where sess_id = sessid 
				and (expiration > now() or expiration isnull);
		return sessdata;
	end;
$$ language plpgsql;

create or replace function destroy_session(sessid text)
returns void as $$
	begin
		delete from connect_session where sess_id = sessid;
		return;
	end;
$$ language plpgsql;

create or replace function clear_sessions()
returns void as $$
	begin
		delete from connect_session;
		return;
	end;
$$ language plpgsql;

create or replace function count_sessions()
returns int as $$
	declare
		thecount int := 0;
	begin
		select count(*) into thecount from connect_session where expiration > now() or expiration isnull;
		return thecount;
	end;
$$ language plpgsql;

create or replace function all_session_ids()
returns setof text as $$
	begin
		return query select sess_id from connect_session where expiration > now() or expiration isnull;
		return;
	end;
$$ language plpgsql;

create or replace function remove_expired()
returns trigger as $$
	begin
		delete from connect_session where expiration < now();
		return null;
	end;
$$ language plpgsql;

create trigger delete_expired_trig
	after insert or update
	on connect_session
	execute procedure remove_expired();