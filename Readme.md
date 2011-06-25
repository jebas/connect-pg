# Connect PostgreSQL

Connect-pg is a middleware session storage for the connect 
framework using PostgreSQL.  Why?  Because sometimes you need a 
relational database handling your data.  

***

## Requirements

* **Production**
	* *[connect](https://github.com/senchalabs/connect) 1.5.0 or later* The HTTP server framework used by Express.
	* *[pg](https://github.com/brianc/node-postgres) 0.50 or later* The node.js client for PostgreSQL.  
	* *[PostgreSQL](http://www.postgresql.org) 8.4 or later* The database.
* **Development**
	* *[jasmine-node](https://github.com/mhevery/jasmine-node)* The BDD style testing framework for JavaScript.  
	* *[pgtap](http://pgtap.org)* TAP style testing framework for PostgreSQL databases.  
	
***

## Installation 

Installation is done in two steps.  The first is to install the JavaScript library, 
and the second is to add the tables to the PostgreSQL database.  

1. **Install the JavaScript library**

	*Standard Method:* npm install connect-pg (eventually)
	
	*Manual Method:* [Download](https://github.com/jebas/connect-pg) the files to your
	server.  The only file your script needs access to is connect-pg.js found in the lib
	directory.  
	
2. **Add the tables to your database**

	In the lib directory, there is a file called session_install.sql.  Assuming that you
	have already created a database, and that you have access to a user that has been 
	granted the appropriate permissions (See the [PostgreSQL](http://www.postgresql.org/docs)
	for instructions), all you need to do is execute session_install.sql inside the database.
	
	`psql -d pgstore -U postgres -f session_install.sql`
	
	If you are planning to use the same role/user in your JavaScript application, you are 
	done with the installation.  However, all of the functions were created with security
	definer.  This will allow you to create another role that only has execute permissions 
	for the functions.  
	
	
	>`grant execute on function web.set_session_data(text, text, timestamp with time zone) to scriptrole;`
	>`grant execute on function web.get_session_data(text) to scriptrole;`
	>`grant execute on function web.destroy_session(text) to scriptrole;`
	>`grant execute on function web.clear_sessions() to scriptrole;`
	>`grant execute on function web.count_sessions() to scriptrole;`
	>`grant execute on function web.all_session_ids() to scriptrole;`