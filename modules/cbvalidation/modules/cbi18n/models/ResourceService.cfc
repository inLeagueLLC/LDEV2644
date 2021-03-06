<!-----------------------------------------------------------------------
********************************************************************************
Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.ortussolutions.com
********************************************************************************
Inspired by Paul Hastings
----------------------------------------------------------------------->
<cfcomponent hint="Reads and parses java resource bundles with a nice integration for replacement and MVC usage"
			 output="false"
			 singleton>

	<cfproperty name="log" 	inject="logbox:logger:{this}">

	<cfset instance = {}>

<!------------------------------------------- CONSTRUCTOR ------------------------------------------->

	<cffunction name="init" access="public" returntype="ResourceService" hint="Constructor" output="false">
		<cfargument name="controller" 	inject="coldbox">
		<cfargument name="i18n"		   	inject="i18n@cbi18n">
		<cfscript>
			// store variables
			variables.controller 	= arguments.controller;
			variables.i18n			= arguments.i18n;

			// check if localization struct exists in memory, else create it.
			if( NOT arguments.controller.settingExists( "RBundles" ) ){
				arguments.controller.setSetting( "RBundles", structNew() );
			}

			// setup local instance references
			instance.aBundles				= arguments.controller.getSetting( "RBundles" );
			instance.defaultLocale 			= arguments.controller.getSetting( "DefaultLocale" );
			instance.defaultResourceBundle  = arguments.controller.getSetting( "DefaultResourceBundle" );
			instance.unknownTranslation 	= arguments.controller.getSetting( "UnknownTranslation" );
			instance.resourceBundles 		= arguments.controller.getSetting( "ResourceBundles" );
			instance.logUnknownTranslation	= arguments.controller.getSetting( "logUnknownTranslation" );

			return this;
		</cfscript>
	</cffunction>

<!------------------------------------------- PUBLIC ------------------------------------------->

	<cffunction name="getBundles" access="public" output="false" returntype="struct" hint="Reference to loaded bundles">
		<cfscript>
			return instance.aBundles;
		</cfscript>
	</cffunction>

	<cffunction name="getLoadedBundles" access="public" output="false" returntype="array" hint="Get a list of all loaded bundles">
		<cfscript>
			return structKeyArray( instance.aBundles );
		</cfscript>
	</cffunction>

	<cffunction name="getDefaultLocale" access="public" output="false" returntype="string" hint="Reference to the default application locale">
		<cfscript>
			return instance.defaultLocale;
		</cfscript>
	</cffunction>

	<cffunction name="getDefaultResourceBundle" access="public" output="false" returntype="string" hint="Reference to the default application resource bundle location">
		<cfscript>
			return instance.defaultResourceBundle;
		</cfscript>
	</cffunction>

	<cffunction name="getUnknownTranslation" access="public" output="false" returntype="string" hint="Reference to the default application unknown translation string">
		<cfscript>
			return instance.unknownTranslation;
		</cfscript>
	</cffunction>

	<cffunction name="loadBundle" access="public" output="false" hint="Tries to load a resource bundle into ColdBox memory if not loaded already" returntype="any">
		<cfargument name="rbFile"   required="true" 	type="string" 	hint="This must be the path + filename UP to but NOT including the locale. We auto-add .properties to the end alongside the locale">
		<cfargument name="rbLocale" required="false"  	type="string" 	default="en_US" 	hint="The locale of the bundle to load">
		<cfargument name="force" 	required="false"  	type="boolean" 	default="false" 	hint="Forces the loading of the bundle even if its in memory">
		<cfargument name="rbAlias" 	required="false"  	type="string" 	default="default" 	hint="The unique alias name used to store this resource bundle in memory. The default name is the name of the rbFile passed if not passed.">

		<!--- Setup rbAlias if not passed --->
		<cfif NOT structKeyExists( arguments, "rbAlias" ) or NOT len( arguments.rbAlias )>
			<cfset arguments.rbFile  = replace( arguments.rbFile, "\", "/", "all" )>
			<cfset arguments.rbAlias = listLast( arguments.rbFile, "/" )>
		</cfif>

		<!--- Verify bundle register name exists --->
		<cfif NOT structKeyExists( instance.aBundles, arguments.rbAlias )>
			<cflock name="rbregister.#hash( arguments.rbFile & arguments.rbAlias )#" type="exclusive" timeout="10" throwontimeout="true">
				<cfif NOT structKeyExists( instance.aBundles, arguments.rbAlias )>
					<cfset instance.aBundles[ arguments.rbAlias ] = structnew()>
				</cfif>
			</cflock>
		</cfif>

		<!--- Verify bundle register locale exists or forced --->
		<cfif NOT structKeyExists( instance.aBundles[ arguments.rbAlias ], arguments.rbLocale ) OR arguments.force>
			<cflock name="rbload.#hash( arguments.rbFile & arguments.rbLocale )#" type="exclusive" timeout="10" throwontimeout="true">
				<cfscript>
				if( NOT structKeyExists( instance.aBundles[ arguments.rbAlias ], arguments.rbLocale ) OR arguments.force ){
					// load a bundle and store it.
					instance.aBundles[ arguments.rbAlias ][ arguments.rbLocale ] = getResourceBundle(rbFile=arguments.rbFile, rbLocale=arguments.rbLocale);
					// logging
					if( log.canDebug() ){
						log.debug( "Loaded bundle: #arguments.rbFile#:#arguments.rbAlias# for locale: #arguments.rbLocale#, forced: #arguments.force#" );
					}
				}
				</cfscript>
			</cflock>
		</cfif>

		<cfreturn this>
	</cffunction>

	<cffunction name="getResource" access="public" output="false" returnType="any" hint="Get a resource from a specific loaded bundle and locale">
		<cfargument name="resource" type="any" required="true" hint="The resource (key) to retrieve from the main loaded bundle.">
		<cfargument name="default"  type="any" required="false" hint="A default value to send back if the resource (key) not found" >
		<cfargument name="locale"   type="any" required="false" default="#variables.i18n.getfwLocale()#" hint="Pass in which locale to take the resource from. By default it uses the user's current set locale" >
		<cfargument name="values" 	type="any" required="false" hint="An array, struct or simple string of value replacements to use on the resource string"/>
		<cfargument name="bundle" 	type="any" required="false"	default="default" hint="The bundle alias to use to get the resource from when using multiple resource bundles. By default the bundle name used is 'default'">
		<cfscript>
			var thisBundle 		= structnew();
			var thisLocale 		= arguments.locale;
			var rbFile 			= "";

			// check for resource@bundle convention:
			if( find( "@", arguments.resource ) ){
				arguments.bundle 	= listLast( arguments.resource, "@" );
				arguments.resource 	= listFirst( arguments.resource, "@" );
			}

			try{

				// Check if the locale has a language bundle loaded in memory
				if( !structKeyExists( instance.aBundles, arguments.bundle ) OR
					( structKeyExists( instance.aBundles, arguments.bundle ) AND NOT structKeyExists( instance.aBundles[ arguments.bundle ], arguments.locale ) )
				){
					// Try to load the language bundle either by default or config search
					if( arguments.bundle eq "default" ){
						rbFile = instance.defaultResourceBundle;
					} else if( structKeyExists( instance.resourceBundles, arguments.bundle ) ) {
						rbFile = instance.resourceBundles[ arguments.bundle ];
					}
					loadBundle( rbFile=rbFile, rbLocale=arguments.locale, rbAlias=arguments.bundle );
				}

				// Get the language reference now
				thisBundle = instance.aBundles[ arguments.bundle ][ arguments.locale ];
			}
			catch(Any e){
				throw(message="Error getting language (#arguments.locale#) bundle for resource (#arguments.resource#). Exception Message #e.message#",
					   detail=e.detail & e.tagContext.toString(),
					   type="ResourceBundle.BundleLoadingException");
			}

			// Check if resource does NOT exists?
			if( NOT structKeyExists( thisBundle, arguments.resource ) ){

				// if logging enable
				if( instance.logUnknownTranslation ){
					log.error( instance.unknownTranslation & " key: #arguments.resource#" );
				}

				// Check default and return if sent
				if( structKeyExists( arguments, "default" ) ){
					return arguments.default;
				}

				// Check unknown translation setting
				if( len( instance.unknownTranslation ) ){
					return instance.unknownTranslation & " key: #arguments.resource#";
				}

				// Else return nasty unknown string.
				return "_UNKNOWNTRANSLATION_FOR_#arguments.resource#_";
			}

			// Return Resource with value replacements
			if( structKeyExists( arguments, "values" ) ){
				return formatRBString( thisBundle[ arguments.resource ], arguments.values );
			}

			// return from bundle
			return thisBundle[ arguments.resource ];
		</cfscript>
	</cffunction>

	<!--- ******************************************************************* --->
	<!--- ************************* UTILITY METHODS ************************* --->
	<!--- ******************************************************************* --->

	<cffunction name="getResourceBundle" access="public" returntype="struct" output="false" hint="Reads,parses and returns a resource bundle in struct format">
		<cfargument name="rbFile"   required="true"   type="any" hint="This must be the path + filename UP to but NOT including the locale. We auto-add the local and .properties to the end.">
		<cfargument name="rbLocale" required="false"  type="any" default="en_US" hint="The locale of the resource bundle">
		<cfscript>
			var resourceBundle =structNew();
			var thisKEY = "";
			var thisMSG = "";
			var keys = "";
			var rbFilePath = arguments.rbFile & iif( len( arguments.rbLocale ), de("_"), de("") ) & arguments.rbLocale & ".properties";
			var rbFullPath = rbFilePath;
			var fis = "";
			var fir = "";
			var rb = "";

			// Try to locate the path using the coldbox plugin utility
			rbFullPath = variables.controller.locateFilePath( rbFilePath );

			// Validate Location
			if( NOT len( rbFullPath ) ){
				throw("The resource bundle file: #rbFilePath# does not exist. Please check your path", "FullPath: #rbFullPath#", "ResourceBundle.InvalidBundlePath");
			}

			//create a file input stream with file location
			fis = createObject( "java", "java.io.FileInputStream" ).init( rbFullPath );
			fir = createObject( "java", "java.io.InputStreamReader" ).init( fis, "UTF-8" );
			//Init RB with file Stream
			rb = createObject( "java", "java.util.PropertyResourceBundle").init( fir );
			try{
				//Get Keys
				keys = rb.getKeys();

				//Loop through property keys and store the values into bundle
				while( keys.hasMoreElements() ){
					thisKEY = keys.nextElement();
					resourceBundle[ thisKEY ] = rb.handleGetObject( thisKEY );
				}

			}
			catch(Any e){
				fis.close();
				$rethrow( e );
			}

			// Close the input stream
			fis.close();

			return resourceBundle;
		</cfscript>
	</cffunction>

	<cffunction name="getRBString" access="public" output="false" returntype="any" hint="Returns a given key from a specific resource bundle file and locale. NOT FROM MEMORY">
		<cfargument name="rbFile" 	required="true" 	type="any" hint="This must be the path + filename UP to but NOT including the locale. We auto-add the local and .properties to the end.">
		<cfargument name="rbKey" 	required="true" 	type="any" hint="The key to retrieve">
		<cfargument name="rbLocale" required="false" 	type="any" default="en_US" hint="The locale of the bundle. Default is en_US">
		<cfargument name="default"  required="false" 	type="any" hint="A default value to send back if resource not found" >
		<cfscript>
			// text message to return
			var rbString="";
			var fis = "";
			var rb = "";

			// default locale?
			if( NOT len( arguments.rbLocale ) ){ arguments.rbLocale = instance.defaultLocale; }

			//prepare the file
	       	var rbFilePath = arguments.rbFile & "_#arguments.rbLocale#.properties";

			// Try to locate the path using the coldbox plugin utility
			var rbFullPath = variables.controller.locateFilePath( rbFilePath );

			// Validate Location
			if( NOT len( rbFullPath ) ){
				throw("The resource bundle file: #rbFilePath# does not exist. Please check your path", "FullPath: #rbFullPath#", "ResourceBundle.InvalidBundlePath");
			}

			//read file
			fis = createObject("java","java.io.FileInputStream").init( rbFullPath );
			rb = createObject("java","java.util.PropertyResourceBundle").init( fis );

			try{
				// Retrieve string
				rbString = rb.handleGetObject( arguments.rbKey );
			}
			catch(Any e){
				fis.close();
				$rethrow( e );
			}

			// Close file
			fis.close();

		    //Check if found?
		    if( isDefined( "rbString" ) ){
		    	return rbString;
		   	}
		    // Check default?
		    if( structKeyExists( arguments, "default" ) ){ return arguments.default; }

		    // Nothing to return, throw it
		    throw("Fatal error: resource bundle #arguments.rbFile# does not contain key #arguments.rbKey#","","ResourceBundle.RBKeyNotFoundException");
		</cfscript>
	</cffunction>

	<cffunction name="getRBKeys" access="public" output="false" returntype="array" hint="Returns an array of keys from a specific resource bundle">
		<cfargument name="rbFile" 	required="true" 	type="any" hint="This must be the path + filename UP to but NOT including the locale. We auto-add the local and .properties to the end.">
		<cfargument name="rbLocale" required="false" 	type="any" default="" hint="The locale to use, if not passed, defaults to default locale.">
		<cfscript>
	       	var keys 	= arrayNew(1);
	       	var rbKeys 	= "";
	       	var fis 	= "";
			var rb 		= "";

			// default locale?
			if( NOT len( arguments.rbLocale ) ){ arguments.rbLocale = instance.defaultLocale; }

	       	//prepare the file
	       	var rbFilePath = arguments.rbFile & "_#arguments.rbLocale#.properties";

			// Try to locate the path using the coldbox plugin utility
			var rbFullPath = variables.controller.locateFilePath( rbFilePath );

			// Validate Location
			if( NOT len( rbFullPath ) ){
				throw("The resource bundle file: #rbFilePath# does not exist. Please check your path", "FullPath: #rbFullPath#", "ResourceBundle.InvalidBundlePath");
			}

			//read file
			fis = createObject("java","java.io.FileInputStream").init( rbFullPath );
			rb = createObject("java","java.util.PropertyResourceBundle").init( fis );

			try{
				//Get Keys
				rbKeys = rb.getKeys();
				//Loop through Keys and get the elements.
            	while( rbKeys.hasMoreElements() ){
            		arrayAppend( keys, rbKeys.nextElement() );
            	}
			}
			catch(Any e){
				fis.close();
				$rethrow( e );
			}

            //Close it up
            fis.close();

            return keys;
     	</cfscript>
	</cffunction>

	<cffunction name="formatRBString" access="public" output="false" returnType="string" hint="performs messageFormat like operation on compound rb string. So if you have a string with {1} it will replace it. You can also have multiple and send in an array to do replacements.">
		<cfargument name="rbString" 		required="true" type="string">
	    <cfargument name="substituteValues" required="true" type="any" hint="Array, Struct or single value to format.">
	    <cfscript>
	    	var x 		= 0;
	    	var tmpStr 	= arguments.rbString;
	    	var valLen 	= 0;
	    	var thisKey = "";

	    	// Array substitutions by position
	    	if( isArray( arguments.substituteValues ) ){
	    		valLen = arrayLen( arguments.substituteValues );

	    		for(x=1; x lte valLen; x=x+1){
	    			tmpStr = replace( tmpStr, "{#x#}", arguments.substituteValues[ x ], "ALL" );
	    		}

	    		return tmpStr;
	    	}
	    	// Struct substitutions by key
	    	else if( isStruct( arguments.substituteValues ) ){
	    		for( thisKey in arguments.substituteValues ){
	    			tmpStr = replaceNoCase( tmpStr, "{#lcase( thisKey )#}", arguments.substituteValues[ lcase( thisKey ) ], "ALL" );
	    		}
	    		return tmpStr;
	    	}

	    	// Single simple substitution
	    	return replace( arguments.rbString, "{1}" , arguments.substituteValues, "ALL" );
	    </cfscript>
	</cffunction>

	<cffunction name="messageFormat" access="public" output="false" returnType="string" hint="performs messageFormat on compound rb string">
		<cfargument name="thisPattern" 	required="yes" type="string" hint="pattern to use in formatting">
		<cfargument name="args" 		required="yes" hint="substitution values, simple or array">
		<cfargument name="thisLocale" 	required="no"  default="" hint="locale to use in formatting, defaults to en_US">
		<cfscript>
			var pattern = createObject("java","java.util.regex.Pattern");
			var regexStr="(\{[0-9]{1,},number.*?\})";
			var p="";
			var m="";
			var i=0;
			var thisFormat="";
			var inputArgs = arguments.args;
			var lang="";
			var country="";
			var variant="";
			var tLocale="";

			//locale?
			if( NOT len(arguments.thisLocale) ){ arguments.thisLocale = instance.defaultLocale; }

			//Create correct java locale
			lang = listFirst(arguments.thisLocale,"_");
	        country = listGetAt(arguments.thisLocale,2,"_");
	        variant = listLast(arguments.thisLocale,"_");
	        tLocale = createObject("java","java.util.Locale").init(lang,country,variant);

	        // Check if input arguments not an array, then inflate to an array.
	        if( NOT isArray(inputArgs) ){
	        	inputArgs = listToArray(inputArgs);
	        }

	        // Create the message format
	        thisFormat = createObject("java","java.text.MessageFormat").init(arguments.thisPattern,tLocale);

			//let's make sure any cf numerics are cast to java datatypes
	        p = pattern.compile(regexStr,pattern.CASE_INSENSITIVE);
	        m = p.matcher(arguments.thisPattern);
	        while( m.find() ){
	        	i = listFirst(replace(m.group(),"{",""));
	        	inputArgs[i]=javacast("float",inputArgs[i]);
	        }

	        arrayPrepend(inputArgs,"");
	        return thisFormat.format(inputArgs.toArray());
		</cfscript>
	</cffunction>

	<cffunction name="verifyPattern" access="public" output="no" returnType="boolean" hint="Performs verification on MessageFormat pattern">
    	<cfargument name="pattern" required="true" type="string" hint="format pattern to test">
		<cfscript>
	        var test = "";

	        try {
	        	test = createObject("java", "java.text.MessageFormat").init( arguments.pattern );
	        }
	        catch (Any e) {
	            return false;
	        }

	        return true;
		</cfscript>
	</cffunction>

<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>
