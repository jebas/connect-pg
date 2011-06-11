-- Database tests for pgStore using PGTap.

-- If this were an MCV setup the database is treated as the model.

begin;
select plan(14);

-- table tests
select has_table('connect_session', 'There should be a session table.');

select has_column('connect_session', 'sess_id', 'Needs to have a session id column.');
select col_type_is('connect_session', 'sess_id', 'text', 'Session id is a string.');
select col_is_pk('connect_session', 'sess_id', 'The session id is the primary key');

select has_column('connect_session', 'sess_data', 'Needs to store the session data.');
select col_type_is('connect_session', 'sess_data', 'text', 'Session data is text.');

-- set function tests
select has_function('set_session_data', array['text', 'text'], 'Needs a set session data function.');

-- set function adds data
delete from connect_session;
select set_session_data('bedrock', 'Fred Flintstone');
prepare session_test as select * from connect_session;
prepare initial_session as values ('bedrock', 'Fred Flintstone');
select results_eq('session_test', 'initial_session', 'set_session_data needs to enter data.');

-- set function updates data
-- this is dependent on the previous test succeeding.
prepare session_update as select set_session_data('bedrock', 'Barney Rubble');
prepare update_session as values ('bedrock', 'Barney Rubble');
select lives_ok('session_update', 'function needs to update as well as insert.');
select results_eq('session_test', 'update_session', 'set_session needs to update data.');

-- get function tests
select has_function('get_session_data', array['text'], 'Needs a get_session_data function.');

-- get function pulls data
-- dependent on previous test.
prepare session_get as select get_session_data('bedrock');
prepare bedrock_session_data as values ('Barney Rubble');
select results_eq('session_get', 'bedrock_session_data', 'Needs to pull session data.');

-- destroy function tests
select has_function('destroy_session', array['text'], 'Needs to have a destroy function.');

-- destroy removes data. 
-- This is using previous tests.  
select destroy_session('bedrock');
select results_eq('session_get', array[null], 'Data needs to be deleted');

select * from finish();
rollback;
