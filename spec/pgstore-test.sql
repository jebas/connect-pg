-- Database tests for pgStore using PGTap.

-- If this were an MCV setup the database is treated as the model.

begin;
select plan(20);

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
select clear_sessions();
select set_session_data('bedrock', 'Fred Flintstone');
prepare session_test as select * from connect_session;
prepare initial_session as values ('bedrock', 'Fred Flintstone');
select results_eq('session_test', 'initial_session', 'set_session_data needs to enter data.');

-- set function updates data
prepare session_update as select set_session_data('bedrock', 'Barney Rubble');
prepare update_session as values ('bedrock', 'Barney Rubble');
select clear_sessions();
select set_session_data('bedrock', 'Fred Flintstone');
select lives_ok('session_update', 'function needs to update as well as insert.');
select results_eq('session_test', 'update_session', 'set_session needs to update data.');

-- get function tests
select has_function('get_session_data', array['text'], 'Needs a get_session_data function.');

-- get function pulls data
prepare session_get as select get_session_data('bedrock');
prepare bedrock_session_data as values ('Fred Flintstone');
select clear_sessions();
select set_session_data('bedrock', 'Fred Flintstone');
select results_eq('session_get', 'bedrock_session_data', 'Needs to pull session data.');

-- destroy function tests
select has_function('destroy_session', array['text'], 'Needs to have a destroy function.');

-- destroy removes data. 
select clear_sessions();
select set_session_data('bedrock', 'Fred Flintstone');
select destroy_session('bedrock');
select results_eq('session_get', array[null], 'Data needs to be deleted');

-- clear function tests
select has_function('clear_sessions', 'Needs a clear function.');

-- clear removes all data.
select set_session_data('flintstone', 'fred');
select set_session_data('rubble', 'barney');
select clear_sessions();
select results_eq('select cast(count(*) as int) from connect_session', 'values (0)', 'There should be no data available.');

-- length function tests.
select has_function('count_sessions', 'Needs a count for the length function.'); 

-- length counts the number of records.
select clear_sessions();
select set_session_data('flintstone', 'fred');
select set_session_data('rubble', 'barney');
select results_eq('select count_sessions()', 'values (2)', 'This should equal the total number of records.');

-- all function tests.
select has_function('all_session_ids', 'Needs a listing of all session ids.');

-- test all returns
select clear_sessions();
select set_session_data('flintstone', 'fred');
select set_session_data('rubble', 'barney');
select set_session_data('slade', 'mister');
prepare session_ids as values ('flintstone'), ('rubble'), ('slade');
select results_eq('select all_session_ids()', 'session_ids', 'It should return all ids.');

select * from finish();
rollback;
