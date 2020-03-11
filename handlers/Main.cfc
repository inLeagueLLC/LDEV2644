component extends="coldbox.system.EventHandler"{

	// Default Action
	function index( event, rc, prc ){
		setupDatabase();
	
		var config = EntityLoad( "Config", {}, true );
	
		if ( event.getValue( 'ormReload', 0 ) ) {
			var time1 = getTickCount();

			ormReload();

			var time2 = getTickCount();

			prc.ticks = time2 - time1;
		}
		
		event.setView("main/index");
	}

	// Do something
	function doSomething( event, rc, prc ){
		relocate( "main.index" );
	}

	/************************************** IMPLICIT ACTIONS *********************************************/

	function onAppInit( event, rc, prc ){
		setupDatabase();
	}

	function onRequestStart( event, rc, prc ){

	}

	function onRequestEnd( event, rc, prc ){

	}

	function onSessionStart( event, rc, prc ){

	}

	function onSessionEnd( event, rc, prc ){
		var sessionScope = event.getValue("sessionReference");
		var applicationScope = event.getValue("applicationReference");
	}

	function onException( event, rc, prc ){
		//Grab Exception From private request collection, placed by ColdBox Exception Handling
		var exception = prc.exception;
		//Place exception handler below:

	}

	function onMissingTemplate( event, rc, prc ){
		//Grab missingTemplate From request collection, placed by ColdBox
		var missingTemplate = event.getValue("missingTemplate");

	}

	private function initializeDatabase() {
		queryExecute( "
			CREATE TABLE `config` (
			`bootstrapped` tinyint(1) NOT NULL DEFAULT 0,
			`created_date` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
			PRIMARY KEY( `bootstrapped` )
			)" );

			queryExecute( "INSERT INTO config( bootstrapped ) VALUES( 0 )" );
	}

	private function setupDatabase() {
		try {
			var bootstrappedQry = queryExecute( "SELECT * from config" );
		}
		catch ( any e ) {
			initializeDatabase();
			var bootstrappedQry = queryExecute( "SELECT * from config" );
		}

		var bootstrapped = bootstrappedQry.bootstrapped;
	
		if ( !bootstrapped ) {
			createAllTheTables();
			createAllTheFiles();
		}	
	}

	private function createAllTheTables( numeric count = 1000 ) {
		for ( var x = 1; x <= count; x++ ) {
			var tableName = 'table' & x;
			queryExecute( "
            CREATE TABLE `#tableName#` (
              `id` char(35) NOT NULL,
              `name` varchar(50) NOT NULL,
              `created_date` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
              `modified_date` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
              PRIMARY KEY (`id`)
            )
		");
			queryExecute( "INSERT INTO #tableName# ( `id`, `name` ) VALUES( #x#, 'A name for entity #x#' ) ");		
	
		}
	}
	public function createAllTheFiles( numeric count = 1000 ) {
		
		for ( var x = 1; x <= count; x++ ) {
			var fileName = '/models/Entity' & x & '.cfc';
			if (! fileExists( fileName ) ) {
				var fileText = '
				component extends="cborm.models.ActiveEntity" persistent="true" table="table#x#" output="false" {
					property name="id" column="id" ormtype="string" fieldtype="id" generator="increment";
					property name="name" column="name" ormtype="string";
					property name="created_date" column="created_date" fieldtypep="timestamp";
					property name="modified_date" column="modified_date" fieldtype="timestamp";
				}
			';
				filewrite( fileName, fileText );
			}
		}

		queryExecute( "UPDATE config SET bootstrapped = 1 WHERE bootstrapped = 0" );
	}

}