xquery version "1.0";

declare namespace anno="http://exist-db.org/xquery/annotate";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare copy-namespaces no-preserve, no-inherit;

declare default element namespace "http://www.tei-c.org/ns/1.0";

import module namespace tei2html="http://exist-db.org/xquery/tei2html" at "tei2html.xql";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

(:
declare option exist:serialize "method=xhtml media-type=text/html add-exist-id=all indent=yes omit-xml-declaration=yes";


:)

declare boundary-space strip;
declare option exist:serialize "method=xhtml media-type=text/html omit-xml-declaration=yes indent=yes 
        doctype-public=-//W3C//DTD&#160;XHTML&#160;1.0&#160;Transitional//EN
doctype-system=http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd";

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

declare function local:books-table( $books as element()*, $show-entries as xs:boolean){
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


let $uri := request:get-parameter("uri", () ),
    $node-id := request:get-parameter("node-id", () ),
    $doc := if( exists($uri)) then  doc($uri) else (),
    $node := if( exists($doc) and exists($node-id)) then util:node-by-id($doc, $node-id) else ()
    
    
    
(: xmlns="http://www.w3.org/1999/xhtml"  :)
return <html > 
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <head>
      <title>{
        if( exists($node)) then (
            'Entry: ',
            for $h in $node/head return string($h)
        )else 
            'All Encyclopedias'
      
      }</title>
    </head>
    <body>{
      if( exists($node)) then (
         <div class="tei-entry"> {
          
          tei2html:entry( $node )   
      
        }</div>
      ) else      
          local:books-table(local:books-list( 
             if( exists($doc) ) then $doc/tei:TEI/teiHeader/fileDesc
             else collection($config:data-collection)/tei:TEI/teiHeader/fileDesc  ),
             exists($doc)
          ) 
       
    
    }</body>    
</html>
    
