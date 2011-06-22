-- Database tests for pgStore using PGTap.

-- If this were an MCV setup the database is treated as the model.

begin;
-- \i pgtap.sql

select plan(32);

-- schema tests
select has_schema('web', 'There should be a web sessions schema.');

-- table tests
select has_table('web', 'session', 'There should be a session table.');

select has_column('web', 'session', 'sess_id', 'Needs to have a session id column.');
select col_type_is('web', 'session', 'sess_id', 'text', 'Session id is a string.');
select col_is_pk('web', 'session', 'sess_id', 'The session id is the primary key');

select has_column('web', 'session', 'sess_data', 'Needs to store the session data.');
select col_type_is('web', 'session', 'sess_data', 'text', 'Session data is text.');

select has_column('web', 'session', 'expiration', 'Needs a time limit on the session.');
select col_type_is('web', 'session', 'expiration', 'timestamp with time zone', 'expiration needs to be a timestamp.');
select col_has_default('web', 'session', 'expiration', 'Needs a default of + one day.');
select has_index('web', 'session', 'expire_idx', array['expiration'], 'Needs an index for the expiration column.');

-- set function tests
select has_function('web', 'set_session_data', array['text', 'text', 'timestamp with time zone'], 'Needs a set session data function.');

-- set function adds data
select web.clear_sessions();
select web.set_session_data('bedrock', 'Fred Flintstone', null);
prepare session_test as select sess_id, sess_data from web.session;
prepare initial_session as values ('bedrock', 'Fred Flintstone');
select results_eq('session_test', 'initial_session', 'set_session_data needs to enter data.');

-- set function updates data
prepare session_update as select web.set_session_data('bedrock', 'Barney Rubble', null);
prepare update_session as values ('bedrock', 'Barney Rubble');
select web.clear_sessions();
select web.set_session_data('bedrock', 'Fred Flintstone', null);
select lives_ok('session_update', 'function needs to update as well as insert.');
select results_eq('session_test', 'update_session', 'set_session needs to update data.');

-- get function tests
select has_function('web', 'get_session_data', array['text'], 'Needs a get_session_data function.');

-- get function pulls data
prepare session_get as select web.get_session_data('bedrock');
prepare bedrock_session_data as values ('Fred Flintstone');
select web.clear_sessions();
select web.set_session_data('bedrock', 'Fred Flintstone', null);
select results_eq('session_get', 'bedrock_session_data', 'Needs to pull session data.');

-- get function should not pull expired data.
select web.clear_sessions();
select web.set_session_data('bedrock', 'Fred Flintstone', timestamp '2001-09-13 00:00');
select results_eq('session_get', 'values (null)', 'should not retrieve expired data.');

-- destroy function tests
select has_function('web', 'destroy_session', array['text'], 'Needs to have a destroy function.');

-- destroy removes data. 
select web.clear_sessions();
select web.set_session_data('bedrock', 'Fred Flintstone', null);
select web.destroy_session('bedrock');
select results_eq('session_get', array[null], 'Data needs to be deleted');

-- clear function tests
select has_function('web', 'clear_sessions', 'Needs a clear function.');

-- clear removes all data.
select web.set_session_data('flintstone', 'fred', null);
select web.set_session_data('rubble', 'barney', null);
select web.clear_sessions();
select results_eq('select cast(count(*) as int) from web.session', 'values (0)', 'There should be no data available.');

-- length function tests.
select has_function('web', 'count_sessions', 'Needs a count for the length function.'); 

-- length counts the number of records.
select web.clear_sessions();
select web.set_session_data('flintstone', 'fred', null);
select web.set_session_data('rubble', 'barney', null);
select results_eq('select web.count_sessions()', 'values (2)', 'This should equal the total number of records.');

-- count does not include expired records.
select web.clear_sessions();
select web.set_session_data('flintstone', 'fred', null);
select web.set_session_data('rubble', 'barney', now() + interval '1 day');
select web.set_session_data('slade', 'mister', now() - interval '1 day');
select results_eq('select web.count_sessions()', 'values (2)', 'This should equal the total number of records.');

-- all function tests.
select has_function('web', 'all_session_ids', 'Needs a listing of all session ids.');

-- test all returns
prepare session_ids as values ('flintstone'), ('rubble'), ('slade');
select web.clear_sessions();
select web.set_session_data('flintstone', 'fred', null);
select web.set_session_data('rubble', 'barney', null);
select web.set_session_data('slade', 'mister', null);
select results_eq('select web.all_session_ids()', 'session_ids', 'It should return all ids.');

-- test all returns
prepare good_session_ids as values ('flintstone'), ('rubble');
select web.clear_sessions();
select web.set_session_data('flintstone', 'fred', null);
select web.set_session_data('rubble', 'barney', now() + interval '1 day');
select web.set_session_data('slade', 'mister', now() - interval '1 day');
select results_eq('select web.all_session_ids()', 'good_session_ids', 'It should not return expired ids.');

-- remove_expired function tests.
select has_function('web', 'remove_expired', 'Needs a function to delete expired records.');

-- remove_expired trigger
select trigger_is('web', 'session', 'delete_expired_trig', 'web', 'remove_expired', 'clean up trigger should be called.');

-- test remove_expired_trig to delete the old messages.
select web.clear_sessions();
select web.set_session_data('flintstone', 'fred', null);
select web.set_session_data('rubble', 'barney', now() + interval '1 day');
select web.set_session_data('slade', 'mister', now() - interval '1 day');
select results_eq('select sess_id from web.session', 'good_session_ids', 'It should delete expired sessions.');

-- test should remove items after an update.
select web.clear_sessions();
select web.set_session_data('flintstone', 'fred', null);
select web.set_session_data('rubble', 'barney', now() + interval '1 day');
select web.set_session_data('slade', 'mister', now() + interval '1 day');
select web.set_session_data('slade', 'mister', now() - interval '1 day');
select results_eq('select sess_id from web.session', 'good_session_ids', 'It should delete expired sessions after update.');

select * from finish();
rollback;
