xquery version "1.0";

declare namespace browse="http://exist-db.org/xquery/browse";
declare namespace anno="http://exist-db.org/xquery/annotate";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare copy-namespaces no-preserve, no-inherit;
declare boundary-space strip;


declare option exist:serialize "method=xhtml media-type=text/html omit-xml-declaration=yes indent=yes 
        doctype-public=-//W3C//DTD&#160;XHTML&#160;1.0&#160;Transitional//EN
doctype-system=http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd";



(:
declare option exist:serialize "method=xhtml media-type=text/html add-exist-id=all indent=yes omit-xml-declaration=yes";

:)


import module namespace dict="http://exist-db.org/xquery/dict" at "dict2html.xql";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";


declare function browse:roots( $nodes as node()*){    
    if( exists($nodes) ) then (
        $nodes/ancestor-or-self::tei:TEI
    ) else if( exists(request:get-parameter("uri", ()  )) )then (
       for $uri in distinct-values(request:get-parameter("uri", () ))
       return if( doc-available($uri)) then
                   doc($uri)//tei:TEI    
              else <error uri="{$uri}">missing book:{ $uri }</error>
                 
              
    )else (
       collection(concat($config:app-root, '/data'))//tei:TEI      
    )    
};

(: the books that are contain $nodes - names, titles :)
declare function browse:booksOf( $nodes as node()*){
        
    $nodes/ancestor-or-self::tei:TEI//teiHeader/fileDesc
};

(: entries containing names or titles :)
declare function browse:entriesOf( $nodes as node()*){
    $nodes/ancestor-or-self::tei:TEI//div[@type="entry"]    
};
(: entries found in books :)
declare function browse:entriesIn( $books as node()*){
    $books//body/div[@type="entry"]   
};

declare function browse:entries-titles( $entries as node()*){
    $entries/head    
};

(: names found into books or entries :)
declare function browse:nameInSummary( $nodes as node()*){
    let $types := distinct-values($nodes//name/@type)
    return 
        for $t in $types return
            element type {
               attribute {'count'}{ count( $nodes//name/@type[ . = $t ])},
               $t
            }
};


declare function browse:name-types_enumerate( $nodes as node()*){
    let $types := distinct-values($nodes//name/@type)
    return 
        for $t in $types 
        let $count := count( $nodes//name/@type[ . = $t ] )
        return
            element {'name'}{
               (: attribute {'count'}{ $count },  :)
               attribute {'name-value'}{ $t },
               concat ($t, ' (', $count, ')')
            }
    
};


(: title elements will contains the specific URL parameters for each axon   :)
declare function browse:node-titles( $nodes as element()*, $level as node(), $step as xs:int ){
    element titles {
        attribute {'count'}{ count($nodes)},
        attribute {'title'}{ $level/@title },
        typeswitch ($nodes[1] )
          case element(tei:TEI) return
             for $title in $nodes//tei:titleStmt  
             let $title2 := if( string($title) = 'Title' ) then 
                                 concat('[',  util:document-name($title), ']') 
                            else $title
             order by string($title2)
             return 
                 element title {
                    attribute uri { document-uri( root($title)) },
                    $title2 
                 }
    
          case element(tei:div) return
             for $title in $nodes/tei:head  
             order by string($title)
             return 
                element title { 
                     attribute uri { document-uri( root($title)) },   
                     attribute entry-node-id { util:node-id($title) },
                   $title 
                }

         case element(tei:name) return
            let $types := distinct-values($nodes/@type)
            return 
                for $t in $types 
                let $count := count( $nodes[@type = $t ])
                order by $t
                return                    
                    element title {
(:                       attribute {'uri'} { document-uri( root($t)) },   
                       attribute {'name-node-id'} { util:node-id($t) },      
:)                       
                       attribute {'name'}{$t},
                       attribute {'count'}{$count},
                       concat( $t, ' (', $count, ')' )
                    }
                    
  
                    
          default return
             <title>no-titles</title>
    }
};




declare function local:change-element-ns-deep ($element as element(), $newns as xs:string) as element(){
  let $newName := QName($newns, local-name($element))
  return
  (element {$newName} {
    $element/@*, for $child in $element/node()
      return
        if ($child instance of element())
        then local:change-element-ns-deep($child, $newns)
        else $child
  })
};
(:  local:change-element-ns-deep($x, "http://www.w3.org/1999/xhtml")  :)

declare function local:books-list( $fileDesc as element()*, $include-entries as xs:boolean){
   for $book in $fileDesc/titleStmt 
     let $root := $book/ancestor-or-self::tei:TEI,
         $entries := $root/text/body/div[@type="entry"]
     
   return 
   element book {
       $book/*,
       element {'language'}{ string($root/text/@xml:lang)  },       
       element uri { document-uri( root($book)) },   
  (:     element uri { concat(util:collection-name($book), '/',  util:document-name($book))}, :)
       element file { util:document-name($book) },
       element node-id { util:node-id($book) },
       if( $include-entries ) then (
           element {'entries'}{ 
             attribute {'count'}{ count($entries) },         
             for $e in $entries return 
                element entry{
                    attribute {'node-id'}{ util:node-id($e) },
                    attribute {'articles'}{ count( $e/div[ @type="article" ]) },
                    $e/head
                }
          }
      )else ()
   }
};


declare function local:books-list( $fileDesc as element()*){
   for $book in $fileDesc/titleStmt 
     let $root := $book/ancestor-or-self::tei:TEI,
         $entries := $root/text/body/div[@type="entry"]
     
   return 
   element book {
       $book/*,
       element {'language'}{ string($root/text/@xml:lang)  },       
       element uri { document-uri( root($book)) },   
  (:     element uri { concat(util:collection-name($book), '/',  util:document-name($book))}, :)
       element file { util:document-name($book) },
       element node-id { util:node-id($book) },
       element {'entries'}{ 
         attribute {'count'}{ count($entries) },         
         for $e in $entries return 
            element entry{
                attribute {'node-id'}{ util:node-id($e) },
                attribute {'articles'}{ count( $e/div[ @type="article" ]) },
                $e/head
            }
      }
   }
};

declare function browse:nameValue( $nodes as item()* ) as xs:string*{
   for $n in $nodes return
   concat( local-name($n), '=', string($n))
};

declare function browse:link-param( $name as xs:string, $values as xs:string* ) as xs:string?{
   if( exists($values) ) then    
       string-join((
         for $v in $values return
         concat( $name, '=', $v )
        ), '&amp;') 
   else ()
};


declare function browse:link-href-base( ) as xs:string?{
    string-join((
       browse:link-param('L1', $browse:L1),
       browse:link-param('L2', $browse:L2),
       browse:link-param('L3', $browse:L3),
       browse:link-param('uri',  for $uri in distinct-values(request:get-parameter("uri", () )) return $uri )
    ),'&amp;')
};

declare function browse:link-href-param( $param-names as xs:string* )as xs:string?{
    string-join((
       for $p in $param-names return
          browse:link-param($p,  request:get-parameter($p, ()  ) )
    ),'&amp;')
};



declare function browse:link( $title as element() ) as element(a){
  element a {
     attribute{'href'}{
        concat('?',
            string-join((
               browse:link-href-base(),
              (: browse:link-href-param(('v1', 'v2', 'v3')), :)              
               browse:nameValue( $title/@* )               
            ),'&amp;')
        )     
     },
     attribute{'title'}{},
     string( $title )  
  }

};

declare function browse:section-as-ul( $section as element(titles), $id as node() ) {
    <h4>{ string($section/@title) }</h4>,
    <ul id="{ $id }">{ 
        for $t in $section/title return 
        element li { browse:link($t) }
   }</ul>
};


declare variable $browse:levels := (
    <level value-names="book" title="Books">books</level>,
    <level value-names="entry" title="Entries">entries</level>,
    <level value-names="name" title="Names">names</level>,
    <level value-names="title" title="Titles" optional="yes">titles</level>
);

(: TODO: make sure there is no duplicatates of levels where the missing levels are set by the order in $browse:levels :)
declare variable $browse:L1 := $browse:levels[ . = request:get-parameter("L1", 'books'  )];
declare variable $browse:L2 := $browse:levels[ . = request:get-parameter("L2", 'entries' )];
declare variable $browse:L3 := $browse:levels[ . = request:get-parameter("L3", () )];
declare variable $browse:L4 := $browse:levels[ . = request:get-parameter("L4", () )];



let $uri := request:get-parameter("uri", () ),
    $node-id := request:get-parameter("node-id", () ),
(:    $doc := if( exists($uri)) then  doc($uri) else (),
    $node := if( exists($doc) and exists($node-id)) then util:node-by-id($doc, $node-id) else (),
:)

(: we need: A. data nodes to extract the lower levels,
            B. List of titles(values) to display for this axon
:)
    $data-1 := 
          if(       $browse:L1 = 'books')   then (   
            browse:roots( () )
          )else if( $browse:L1 = 'names')   then ( 
            (: todo: add node-id to select on the corresponding node :)          
            browse:roots( () )//name[@type]
          )else if( $browse:L1 = 'entries') then (  
            let $entry-node-id := request:get-parameter("entry-node-id", () )
            return
            browse:entriesIn(
                if( false () and string-length( $entry-node-id  ) > 3 ) then
                   util:node-by-id( doc($uri), $entry-node-id)
                else 
                    browse:roots( () ) 
            )
            
 
            
            
          )else(),
    
    

    $data-2 := 
        if( $browse:L1 = 'books')   then (  
            if( $browse:L2 = 'names') then (
                 $data-1//name[@type]
                 (: browse:name-types_enumerate($data-1) :)
            )else if( $browse:L2 = 'entries') then (
                 browse:entriesIn($data-1)
            )else ()
            
        )else if( $browse:L1 = 'names')   then ( 
            if( $browse:L2 = 'book') then (
                 browse:booksOf($data-1)
            )else if( $browse:L2 = 'entries') then (
                 browse:entriesOf($data-1)
            )else ()

        )else if( $browse:L1 = 'entries') then ( 
            if( $browse:L2 = 'book') then (
                
                 root($data-1)
            )else if( $browse:L2 = 'names') then (                
                   $data-1//name[@type]
                 (: browse:name-types_enumerate($data-1) :)
            )else ()
        )else(),


     $titles-1 := browse:node-titles($data-1, $browse:L1, 1),
     $titles-2 := browse:node-titles($data-2, $browse:L2, 2),
     $titles-3 := ()
 
     
     
    
(: xmlns="http://www.w3.org/1999/xhtml"  :)
return <html > 
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <head>
      <title> Browse:{
        if( exists($browse:L1)) then (
           string($browse:L1),
           if( exists($browse:L2)) then (
              concat('/', $browse:L2),
               if( exists($browse:L3)) then (
                   concat('/', $browse:L3)
               )else()
           )else()        
        )else ()
      }</title>
      <script type="text/javascript" src="../resources/scripts/jquery-1.5.js"></script> 
      <script type="text/javascript" src="../resources/scripts/jquery.columnizer.js"></script> 
      <script>
        jQuery(document).ready(function(){{
           $('ul#entities').makeacolumnlists({{cols:3,colWidth:0,equalHeight:true}});
      }}))
      </script>
      
    </head>
    <body>
      <table width="500"><tr>
        <td>
            <a href="?L1=books&amp;L2=entries">Books &gt; Entries</a><br/>
            <a href="?L1=books&amp;L2=names">Books &gt; Names</a><br/>
        </td>
        <td>
              <a href="?L1=entries&amp;L2=names">Entries &gt; Names</a><br/>
              <a href="?L1=entries&amp;L2=books">Entries &gt; Books</a><br/>
        </td>
        <td>
              <a href="?L2=entries&amp;L1=names">Names &gt; Entries </a><br/>
              <a href="?L1=names&amp;L2=books">Names &gt; Books</a><br/>
        </td>
      </tr></table>


      <table border="1" width="600" style="height:300px">
        <tbody>
          <tr valign="top">
            <td width="30%">
               <a href="?L1={ request:get-parameter("L1",())}">All</a>
               { browse:section-as-ul( $titles-1, $browse:L1 )  }
            </td>
            <td width="30%">
              <a href="?L1={ request:get-parameter("L1",())}&amp;L2={ request:get-parameter("L2",()) }">All</a>
              {  browse:section-as-ul( $titles-2, $browse:L2 )}              
            </td>
            <td width="30%">
            </td>
          </tr>
        </tbody>
     </table>
    
    </body>    
</html>
    
