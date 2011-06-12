-- This installs the table and functions for connect-pg.

create table connect_session (
	sess_id text primary key,
	sess_data text
);

create or replace function set_session_data(sessid text, sessdata text) 
returns void as $$
	begin
		loop
			update connect_session set sess_data = sessdata where sess_id = sessid;
			if found then
				return;
			end if;
			begin
				insert into connect_session (sess_id, sess_data) values (sessid, sessdata);
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
		select sess_data into sessdata from connect_session where sess_id = sessid;
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