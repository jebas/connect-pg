# Connect PostgreSQL

Connect-pg is a middleware session storage for the connect framework using 
PostgreSQL.  Why?  Because sometimes you need a relational database 
handling your data.  

## Requirements

* **Production**
	* *[connect](https://github.com/senchalabs/connect) 1.5.0 or later* The HTTP server framework used by Express.
	* *[pg](https://github.com/brianc/node-postgres) 0.50 or later* The node.js client for PostgreSQL.  
	* *[PostgreSQL](http://www.postgresql.org) 9.0 or later* The database.
	* *[pgtap](http://pgtap.org)* TAP style testing framework for PostgreSQL databases.  
* **Development**
	* *[jasmine-node](https://github.com/mhevery/jasmine-node)* The BDD style testing framework for JavaScript.  
	
## Installation 

1. **Setup PostgreSQL to Use Passwords to Log In**

	Refer to PostgreSQL's manual for changing the pg_hba.conf file.  The 
	database needs to be setup so that database users can log into the 
	system using a password.  

2. **Install pgTap into the Database**

	[pgTap](http://pgtap.org) is a development tool that validates whether 
	the database is functioning properly or not.  The same tests can also 
	be used to determine what changes need to be made to the database 
	in an installation or upgrade.  So it needs to be installed first.  The link 
	to their website will provide instructions.  

3. **Install the connect-pg library**

	*Standard Method:* npm install connect-pg
	
	*Manual Method:* [Download](https://github.com/jebas/connect-pg) the 
	files to your server.  The only file your script needs access to is 
	connect-pg.js found in the lib directory.  
	
4. **Install the Testing, Upgrading, and Installation Functions**

	As the superuser for the database, install the functions that test, 
	install, and upgrade the connect-pg database. As shown in the 
	following example:
	
	`psql -d {database name} -U postgres -f {path to file}/session_install.sql`

5. **Run the Database Correction Function**

	As the database's superuser, run the database correction function.  
	This will install the tables and functions into a new database, or it will 
	update an existing database to add the new features.  The following is 
	an example of the command.  

	`psql -d {database name} -U postgres -c 'select correct_web()'`
	
## Usage

Using connect-pg can be done in three easy steps.  

1. After the database has been created, the next step is to let your application is going to 
use connect-pg.  

	`var PGStore = require('connect-pg');`

2. Next establish your database connection string.

	`var connectStr = "tcp://thetester:password@localhost/pgstore";`
	
	`var storeOptions = {'pgConnect': connectStr};`
	
3. Inform the session manager to use connect-pg.  

	* **In connect:**
	
		`connect.session({ store: new PGStore(storeOptions), secret: 'keyboard cat'});`
		
	* **In Express:**
	
		`app.use(express.session({store: new PGStore(storeOptions), secret: 'keyboard cat'}));`
		
## Development 

connect-pg use two testing systems: one for the database, and one for the JavaScript.  

In a traditional model-controller-view (MCV) setup, the database would be considered 
the model and all access to the database is controlled through functions inside the 
database.  pgtap is used to test these functions.  Installation of pgtap is described on
their website.  

The rest of connect-pg could be considered the controller, and it was written in 
JavaScript.  `jasmine-node spec` is all that is needed to run these tests.  

There is no view to setup.  

## LICENSE

This software is using the [MIT](./connect-pg/blob/master/LICENSE) to match the connect license.