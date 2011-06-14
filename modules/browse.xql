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
            element type {
               attribute {'count'}{ $count },
               attribute {'value'}{ $t },
               concat ($t, ' (', $count, ')')
            }
};



declare function browse:node-titles( $nodes as element()*, $section-title as xs:string ){
    element titles {
        attribute {'count'}{ count($nodes)},
        attribute {'title'}{ $section-title },
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
                     attribute node-id { util:node-id($title) },
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
                       attribute {'value'}{$t},
                       attribute {'count'}{$count},
                       concat( $t, ' (', $count, ')' )
                    }
    
          default return
             <title>no-tiles</title>
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


declare function browse:link( $title as element() ) as element(a){
  element a {
     attribute{'href'}{
        concat('?',
            string-join((
               if( string-length($browse:L1) > 0 ) then concat('L1=', $browse:L1) else (),
               if( string-length( $browse:L2) > 0 ) then concat('L2=', $browse:L2) else (),
               if( string-length( $browse:L3) > 0 ) then concat('L3=', $browse:L3) else ()
               , browse:nameValue( $title/@* )               
            ),'&amp;')
        )
     
     },
     attribute{'title'}{},
     string( $title )  
  }

};

declare function browse:section-as-ul( $section as element(titles), $id as xs:string ) {
    <h4>{ string($section/@title) }</h4>,
    <ul id="{ $id }">{ 
        for $t in $section/title return 
        element li { browse:link($t) }
   }</ul>
};



declare variable $browse:L1 := request:get-parameter("L1", 'books'  );
declare variable $browse:L2 := request:get-parameter("L2", 'entries'  );
declare variable $browse:L3 := request:get-parameter("L3", ()  );


let $uri := request:get-parameter("uri", () ),
    $node-id := request:get-parameter("node-id", () ),
    $doc := if( exists($uri)) then  doc($uri) else (),
    $node := if( exists($doc) and exists($node-id)) then util:node-by-id($doc, $node-id) else (),
    
    $level-1 := request:get-parameter("L1", 'books'  ),
    $level-2 := request:get-parameter("L2", 'entries' ),
    $level-3 := request:get-parameter("L3", () ),


(: we need: A. data nodes to extract the lower levels,
            B. List of titles(values) to display for this axon
:)
    $data-1 := 
          if(       $browse:L1 = 'books')   then (   browse:roots( () )
          )else if( $browse:L1 = 'names')   then (   browse:roots( () )//name[@type]
          )else if( $browse:L1 = 'entries') then (  browse:entriesIn( browse:roots( () ))
          )else(),
    

    $data-2 := 
        if( $browse:L1 = 'books')   then (  
            if( $browse:L2 = 'names') then (
                 browse:name-types_enumerate($data-1)
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
                 browse:booksOf($data-1)
            )else if( $browse:L2 = 'names') then (
                 browse:name-types_enumerate($data-1)
            )else ()
        )else(),


     $titles-1 := browse:node-titles($data-1, $browse:L1),
     $titles-2 := browse:node-titles($data-2, $browse:L2)
     
     
    
(: xmlns="http://www.w3.org/1999/xhtml"  :)
return <html > 
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <head>
      <title> Browse:{
        if( exists($level-1)) then (
           $level-1,
           if( exists($level-2)) then (
              concat('/', $level-2),
               if( exists($level-3)) then (
                   concat('/', $level-3)
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
    <body>{
      <table border="1" width="600" style="height:300px">
        <tbody>
          <tr valign="top">
            <td>{  browse:section-as-ul( $titles-1, $browse:L1 )}</td>
            <td>{  browse:section-as-ul( $titles-2, $browse:L2 )}</td>
          </tr>
        </tbody>
     </table>
    }</body>    
</html>
    
