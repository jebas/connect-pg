-- Database tests for pgStore using PGTap.  

begin;

select plan(4);

-- Table setup tests.
select has_table('connect_session', 'There should be a session table.');
select has_column('connect_session', 'sess_id', 'Needs to have a session id column.');
select col_type_is('connect_session', 'sess_id', 'text', 'Session id is a string.');
select col_is_pk('connect_session', 'sess_id', 'The session id is the primary key');

select * from finish();

rollback;