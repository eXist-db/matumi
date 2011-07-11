xquery version "1.0";

module namespace browse="http://exist-db.org/xquery/apps/matumi/browse";

declare namespace anno="http://exist-db.org/xquery/annotate";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";


declare variable $browse:delimiter-uri-node := '___';
declare variable $browse:delimiter-uri-nameNode := '---';

declare variable $browse:URIs :=  (: combine multiple URI and multiple node-id :)                  
        let $u := for $i in request:get-parameter("uri", () ) return 
              element {'URI'}{ 
                  if(  contains($i,  $browse:delimiter-uri-node ) ) then (
                      element {'node-id'}{ fn:substring-after($i, $browse:delimiter-uri-node )  },
                      element {'uri'} {    fn:substring-before($i,$browse:delimiter-uri-node ) }                          
                  
                  ) else if( contains($i,  $browse:delimiter-uri-nameNode ) ) then ( 
                      attribute {'name-node'}{'true'},
                      element {'node-id'}{ fn:substring-after($i,  $browse:delimiter-uri-nameNode )  },
                      element {'uri'} {    fn:substring-before($i, $browse:delimiter-uri-nameNode ) }
                  ) else
                      element {'uri'} { $i }
              },
            $unique-uri := distinct-values( $u/uri )
          
        return (                        
            if( count($u/uri) =  count($unique-uri) ) then ( 
                  $u
               )else (
                  for $i in $unique-uri 
                  let $u2 := $u[uri = $i]
                  return element {'URI'}{
                      if( exists($u2/@name-node)) then attribute {'name-node'}{'true'} else (), 
                      element {'uri'}{ $i },
                      for $n in distinct-values($u2/node-id) 
                        return element {'node-id'}{ $n }
                  }
               )
            )
;   



declare variable $browse:levels := (
    <level value-names="name-type" title="Names" clear="name-type">names</level>, 
    <level value-names="uri" title="Entries" clear="uri_node-id">entries</level>, (:  uri=/db/matumi/data/GSE-eng.xml___3.2.2.2 :)
    <level value-names="uri" title="Books" clear="uri">books</level>             (: uri=/db/matumi/data/GSE-eng.xml :)
);

(:
    <level value-names="title" title="Titles" optional="yes">titles</level>
:)

declare variable $browse:L1 := ($browse:levels[ . = request:get-parameter("L1", () )], $browse:levels[1])[1];
declare variable $browse:L2 := ($browse:levels[ . = request:get-parameter("L2", () )], $browse:levels[ not(. = $browse:L1) ])[1];
declare variable $browse:L3 := ($browse:levels[ . = request:get-parameter("L3", () )], $browse:levels[ not(. = ($browse:L1,$browse:L2)) ])[1];
declare variable $browse:L4 := ($browse:levels[ . = request:get-parameter("L4", () )], $browse:levels[ not(. = ($browse:L1,$browse:L2,$browse:L3)) ])[1];


declare function browse:levels-combo( $level as node(), $pos as xs:int ) as element(select) {
   <select name="L{$pos}" id="L{$pos}" style="width:100%">{
       for $L in $browse:levels return 
       element {'option'}{
           if( $L is $level ) then (
                attribute {'selected'}{'selected'} 
           )else if( $pos = 2 and $L is $browse:L1) then (
                attribute {'disabled'}{'disabled'},
                attribute {'style'}{'display:none'}
           )else (),
           if($pos = 3 ) then (
              if( $L is $browse:L1 or $L is $browse:L2 ) then( 
                   attribute {'disabled'}{'disabled'},
                   attribute {'style'}{'display:none'}
              )else ()
           )else(),     
           attribute {'value'}{ string($L)},
           string($L/@title)
       }
   }</select>
};

(:~
 : create file-node URI depending on the type of the element node.
 :)
declare function browse:makeDocument-Node-URI( $node as node() ) as xs:string {
  fn:string-join((
       document-uri( root($node)),       
       typeswitch ( $node )
          case element(tei:div)  return $browse:delimiter-uri-node
          case element(tei:name) return $browse:delimiter-uri-nameNode
          default return '_node-id_',
       util:node-id($node)
  ),'')

};

declare function browse:change-element-ns-deep ($element as element(), $newns as xs:string) as element(){
  let $newName := QName($newns, local-name($element))
  return
  (element {$newName} {
    $element/@*, for $child in $element/node()
      return
        if ($child instance of element())
        then browse:change-element-ns-deep($child, $newns)
        else $child
  })
};
(:  local:change-element-ns-deep($x, "http://www.w3.org/1999/xhtml")  :)

declare function browse:nameValue( $nodes as item()* ) as xs:string*{
   for $n in $nodes return
   concat( local-name($n), '=', string($n))
};

declare function browse:nameValue( $name as xs:string, $values as xs:string* ) as xs:string?{
   if( exists($values) ) then    
       string-join((
         for $v in $values return
         concat( $name, '=', $v )
        ), '&amp;') 
   else ()
};


declare function browse:link-href-base( $add-uri as xs:boolean ) as xs:string?{
    string-join((
       browse:nameValue('L1', $browse:L1),
       browse:nameValue('L2', $browse:L2),
       browse:nameValue('L3', $browse:L3),
       browse:nameValue('name-type', request:get-parameter("name-type", () )),
       if( $add-uri ) then 
          browse:nameValue('uri',  for $uri in distinct-values(request:get-parameter("uri", () )) return $uri )
       else ()
    ),'&amp;')
};

declare function browse:link-href-param( $param-names as xs:string* )as xs:string?{
    string-join((
       for $p in $param-names return
          browse:nameValue($p,  request:get-parameter($p, ()  ) )
    ),'&amp;')
};

declare function browse:link( $title as element() ) as element(a){
  element a {
     if( exists($title/@href)) then 
        $title/@href
     else   
        attribute{'href'}{
           concat('?',
               string-join((
                  browse:link-href-base( true()),
                  browse:nameValue( $title/@* )               
               ),'&amp;')
           )     
        },
     attribute{'title'}{},
     string( $title )  
  }
};


declare function browse:clean-link( $level as element(), $step as xs:int ) as xs:string {
    let $param := for $p in request:get-parameter-names() return element {$p} { request:get-parameter($i, () ) }
    let $exclude := $level
    
    return
    concat('?',
           string-join((
              browse:link-href-base( true()),
              browse:nameValue( $title/@* )               
           ),'&amp;')
       )     
};


declare function browse:page-head(  ) {
    <head>
      <title> local:{ fn:string-join(($browse:L1, $browse:L2, $browse:L3), '/')  }</title>
		<link rel="stylesheet" type="text/css" href="../resources/fluid960gs/css/reset.css" media="screen" />
		<link rel="stylesheet" type="text/css" href="../resources/fluid960gs/css/text.css" media="screen" />
		<link rel="stylesheet" type="text/css" href="../resources/fluid960gs/css/grid.css" media="screen" />
		<link rel="stylesheet" type="text/css" href="../resources/fluid960gs/css/layout.css" media="screen" />
		<link rel="stylesheet" type="text/css" href="../resources/fluid960gs/css/nav.css" media="screen" />
		<!--[if IE 6]><link rel="stylesheet" type="text/css" href="../resources/fluid960gs/css/ie6.css" media="screen" /><![endif]-->
		<!--[if IE 7]><link rel="stylesheet" type="text/css" href="../resources/fluid960gs/css/ie.css" media="screen" /><![endif]-->      

       <link rel="stylesheet" type="text/css" href="../resources/css/browse.css" media="screen" />
      
      <script type="text/javascript" src="../resources/scripts/head.js"></script>
      <script>
        head.js(
           "../resources/scripts/jquery-1.5.js",
           // "../resources/scripts/jquery.columnizer.js",
           // "../resources/scripts/jquery.form.js",
           "../resources/scripts/jquery.listnav-2.1.js",
           "../resources/scripts/browse.js",
           function(){{
             //$('ul#entities').makeacolumnlists({{cols:3,colWidth:0,equalHeight:true}});
                          
           }}
        );
      </script>
      
    </head>
};

declare function browse:section-as-ul( $section as element(titles)?, $id as node()?, $pos as xs:int) {
    (: <h4>{ string($section/@title) }</h4>, :)
    
    <div class="grid_5">
		<div class="box L-box">
			<h2>{browse:levels-combo( $id,  $pos) }</h2>
			<div class="block L-block">
                <ul id="{ $id }">{ 
                    <li>
                       <a href="?{              
                             string-join((
                               browse:nameValue('L1', $browse:L1),
                               browse:nameValue('L2', $browse:L2),
                               browse:nameValue('L3', $browse:L3)
                            ),'&amp;')
                          }">All ({ count($section/title), ' ',  string($section/@title)} )</a>        
                      
                    </li>,
                    for $t in $section/title return 
                    element li { browse:link($t) }
               }</ul>                
            </div>
		</div>
	</div>
};


declare function browse:page-grid(){ 
 
 	<table summary="Table summary">
		
		<colgroup>
			<col class="colA" />
			<col class="colB" />
			<col class="colC" />
		</colgroup>
		<thead>
			<tr>
				<th colspan="3" class="table-head">Table heading</th>
			</tr>
			<tr>
				<th>Book</th>
				<th>Entry</th>
				<th>Names</th>
			</tr>
		</thead>
		<!-- tfoot>
			<tr>
				<th>Summary</th>
				<td>1</td>
				<th>2</th>
			</tr>
			<tr class="total">
				<th>Total</th>
				<td>3</td>
				<th>4</th>
			</tr>
		</tfoot -->
		<tbody>
			<tr class="odd">
				<th>Book</th>
				<td>Entry</td>
				<td>Names</td>
			</tr>
			<tr>
				<th>Book</th>
				<td>Entry</td>
				<td>Names</td>
			</tr>
	    </tbody>
	</table>
};


declare function browse:page-content($t1 as node()?, $t2 as node()?, $t3 as node()?  ) {
  <div class="container_16">
     <form id="browseForm" action="?"> 
  	  <div class="grid_16">
		<h1 id="branding">
			Matumi - Browser
		</h1>
	  </div><div class="clear"></div>
  
      <div class="grid_16">
    	<ul class="nav main">
    		<li>
    			<a href="#">Item 1</a>
    			<ul>
    				<li>
    					<a href="#">Item 11</a>
    				</li>
    				<li>
    					<a href="#">Item 12</a>
    				</li>
    				<li>
    					<a href="#">Item 13</a>
    				</li>
    			</ul>
    		</li>
    		<li>
    			<a href="#">Item 2</a>
    			<ul>
    				<li>
    					<a href="#">Item 21</a>
    				</li>
    				<li>
    					<a href="#">Item 22</a>
    				</li>
    				<li>
    					<a href="#">Item 23</a>
    				</li>
    			</ul>
    		</li>
    		<li class="secondary">
        		 <input type="checkbox" name="autoUpdate" id="autoUpdate">{
                    if( request:get-parameter("autoUpdate", 'off' ) = 'on') then
                       attribute {'checked'}{ 'true'}
                    else ()
                }</input>
                <label for="autoUpdate">Auto Update</label>&#160;&#160;&#160; 
                <input type="submit" value="Update"/>
    		</li>
         </ul>
      </div>
      <div class="clear"></div> 
      <div class="grid_16">
        <h2 id="page-heading">Page Title</h2>
  	  </div>
	  <div class="clear"></div>
	
	
	{ 
	   browse:section-as-ul( $t1, $browse:L1, 1 ),
	   browse:section-as-ul( $t2, $browse:L2, 2 ),
	   browse:section-as-ul( $t3, $browse:L3, 3 )
	}
	   <div class="clear"></div>
     </form>
    
     <div class="grid_16"> { browse:page-grid() }</div><div class="clear"></div>
  </div>
};


declare function browse:books-table( $books as element()*, $show-entries as xs:boolean){
   <table border="1" cellspacing="0" cellpadding="4">
    <thead>
       <th>Name</th>
       <th>Language</th>
       <th>Entries</th>
       <th>Articles</th>
       <th>URI</th>
    </thead>
    <tbody>{
   
  
   for $book in $books 
   let $articles := sum($book//@articles)
   let $title := if( string($book/title = '' )) then (
                         $book/file/text()  
                   )else string($book/title )
   return (    
       element tr {
           element td{
            <a href="?uri={$book/uri/text()}">{ $title }</a>
           },
           <td align="center">{ $book/language/text() }</td>,
           element td{ count($book/entries/*)},
           element td{ if( $articles > number( $book/entries/@count) ) then ( $articles ) else () },
           element td{  $book/file/text() }
       },
       if( $show-entries ) then (
           element tr {
               element td{
                 attribute {'colspan'}{ 5},
                 element UL{
                   for $e in $book/entries/entry return
                      element li {
                        element a {
                           attribute {'href'}{
                             concat("?uri=", $book/uri, '&amp;node-id=', $e/@node-id )
                           },
    (:                   attribute {'uri'}{ $book/uri/text() },
                           $e/@node-id,
    :)                       
                           if( string( $e/head[1]) != '' ) then (
                              string( $e/head[1]),
                              if( number($e/@articles) > 1 ) then 
                                  concat('(', $e/@articles, ' articles)')
                              else ()
                           )else '--- Title is missing ---'
                           
                        }
                      }
                 }
               }
           }
       )else ()
     )
}</tbody>
   </table>
};

