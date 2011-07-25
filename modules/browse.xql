xquery version "1.0";

declare namespace anno="http://exist-db.org/xquery/annotate";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare copy-namespaces no-preserve, no-inherit;
declare boundary-space strip;

declare option exist:serialize "method=xhtml media-type=text/html omit-xml-declaration=yes indent=yes 
        doctype-public=-//W3C//DTD&#160;XHTML&#160;1.0&#160;Transitional//EN
doctype-system=http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd";

(:
declare option exist:serialize "method=xml media-type=text/xml omit-xml-declaration=no indent=yes";
:)

import module namespace browse="http://exist-db.org/xquery/apps/matumi/browse" at "browse.xqm";

declare function local:page-head(  ) {
    <head>
      <title> local:{ fn:string-join(($browse:LEVELS[1], $browse:LEVELS[2], $browse:LEVELS[3]), '/')  }</title>
		<link rel="stylesheet" type="text/css" href="../resources/fluid960gs/css/reset.css" media="screen" />
		<link rel="stylesheet" type="text/css" href="../resources/fluid960gs/css/text.css" media="screen" />
		<link rel="stylesheet" type="text/css" href="../resources/fluid960gs/css/grid.css" media="screen" />
		<link rel="stylesheet" type="text/css" href="../resources/fluid960gs/css/layout.css" media="screen" />
		<link rel="stylesheet" type="text/css" href="../resources/fluid960gs/css/nav.css" media="screen" />
		<!--[if IE 6]><link rel="stylesheet" type="text/css" href="../resources/fluid960gs/css/ie6.css" media="screen" /><![endif]-->
		<!--[if IE 7]><link rel="stylesheet" type="text/css" href="../resources/fluid960gs/css/ie.css" media="screen" /><![endif]-->      

       <link rel="stylesheet" type="text/css" href="../resources/fluid960gs/css/grid.css" media="screen" />
       <link rel="stylesheet" type="text/css" href="../resources/css/browse.css" media="screen" />
      
      <script type="text/javascript" src="../resources/scripts/head.js"></script>
      <script type="text/javascript" src="../resources/scripts/jquery-1.5.js"></script>
      <script type="text/javascript" src="../resources/scripts/browse.js"></script>
      <script type="text/javascript" src="../resources/scripts/chosen.jquery.js"/>
      <!-- script>head.js("");</script -->       
    </head>
};


declare function local:page-content() {
  <div class="container_16">
     
  	  <div class="grid_16">
		<h1 id="branding">Matumi - Browser</h1>
	  </div><div class="clear"></div>
  
      <div class="grid_16">
    	<ul class="nav main">
    		<li>
    			<a href="#">Item 1</a>
    			<ul>
    				<li><a href="#">Item 11</a></li>
    				<li><a href="#">Item 12</a></li>
    				<li><a href="#">Item 13</a></li>
    			</ul>
    		</li>
    		<li>
    			<a href="#">Item 2</a>
    			<ul>
    				<li><a href="#">Item 21</a></li>
    				<li><a href="#">Item 22</a></li>
    				<li><a href="#">Item 23</a></li>
    			</ul>
    		</li>
    		<li class="secondary"> 
    		      <!--
        		 <input type="checkbox" name="autoUpdate" id="autoUpdate">{
                    if( request:get-parameter("autoUpdate", 'off' ) = 'on') then
                       attribute {'checked'}{ 'true'}
                    else ()
                }</input>
                <label for="autoUpdate">Auto Update</label>&#160;&#160;&#160; 
                <input type="submit" value="Update"/>
                -->
    		</li>
         </ul>
      </div><div class="clear"></div>
      
      <div class="grid_16">
        <h2 id="page-heading">Page Title</h2>
  	  </div><div class="clear"></div>	
	  { browse:level-boxes() }
     <div class="grid_16"> 
        { browse:page-grid( false() ) }
     </div><div class="clear"></div>
  </div>
};

 <html> 
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    { 
      local:page-head(),
      element {'body'}{ local:page-content()  }
    }
</html>
    
