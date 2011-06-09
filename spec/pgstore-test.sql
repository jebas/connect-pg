-- Database tests for pgStore using PGTap.  

begin;

select plan(1);

select pass('My test passed.');

select * from finish();

rollback;