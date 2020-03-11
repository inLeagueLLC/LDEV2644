<cfoutput>

	<h2>All The Files Test App</h2>

	<p>we made all the things! Now load everything in a new application scope by changing the HTTP host!</p>
	<p>If this is the first time you've run the app and the database was just initialized, you may need to <a href="#event.buildLink(to ='Main.index', queryString='ormReload=1' )#">reload the ORM.</a></p>

	<ul>
		<li><a target="_blank" href="localhost:#cgi.server_port#/Main/Index">This page on localhost app</a></li>
		<li><a target="_blank" href="localtest.me:#cgi.server_port#/Main/Index">This page on localtest.me app</a></li>
		<li><a target="_blank" href="http://127.0.0.1:#cgi.server_port#/Main/Index">This page on 127.0.0.1 app</a></li>
		<li><a target="_blank" href="anotherapp.localtest.me:#cgi.server_port#/Main/Index">This page on anotherapp.localtest.me</a></li>
	</ul>

	<cfif event.getValue( 'ormReload', 0 )>
		<p>We reloaded the ORM! It took #prc.ticks#ms!</p>
	</cfif>
</cfoutput>