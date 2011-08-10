module namespace matumi="http://www.asia-europe.uni-heidelberg.de/xquery/matumi";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xql";
import module namespace dict="http://exist-db.org/xquery/dict" at "dict2html.xql";
import module namespace search="http://exist-db.org/xquery/search" at "search.xql";
import module namespace browse="http://exist-db.org/xquery/apps/matumi/browse" at "browse.xqm";
import module namespace browse-books="http://exist-db.org/xquery/apps/matumi/browse-books" at "browse_books.xqm";


declare function matumi:entry($node as node()*, $params as element(parameters)?, $model as item()*) {
    let $doc := request:get-parameter("doc", ())
    let $id := request:get-parameter("id", ())
    return
        if ($id) then
            let $entry := doc($doc)//tei:div[@type = "entry"][@subtype = $id]
            return
                templates:process($node/node(), $entry)
        else
            let $nodeId := request:get-parameter("node", ())
            let $target := util:node-by-id(doc($doc), $nodeId)
            let $entry := $target/ancestor-or-self::tei:div[@type = "entry"]
            return
                templates:process($node/node(), $entry)
};

declare function matumi:encyclopedia-title($node as node()*, $params as element(parameters)?, $model as item()*) {
    $model/ancestor::tei:TEI/tei:teiHeader//tei:titleStmt/tei:title/text()
};

declare function matumi:encyclopedia-subjects($node as node()*, $params as element(parameters)?, $model as item()*) {
    $model/@subtype/string()
};

declare function matumi:format-entry($node as node()*, $params as element(parameters)?, $model as item()*) {
    dict:entry($model)
};

declare function matumi:tabs($node as node()*, $params as element(parameters)?, $model as item()*) {
    let $uri := replace(request:get-uri(), "^.*/([^/]+)$", "$1")
    let $log := util:log("DEBUG", ("$uri = ", $uri))
    return
        <ul class="tabs">{ for $child in $node/node() return matumi:process-tabs($child, $uri) }</ul>
};

declare function matumi:process-tabs($node as node(), $active as xs:string) {
    typeswitch ($node)
        case element(a) return
            <a>
            { 
                $node/@href,
                if ($node/@href eq $active) then
                    attribute class { "active" }
                else
                    (),
                $node/node()
            }
            </a>
        case element() return
            element { node-name($node) } {
                $node/@*, for $child in $node/node() return matumi:process-tabs($child, $active)
            }
        default return
            $node
};

declare function matumi:search($node as node()*, $params as element(parameters)?, $model as item()*) {
    let $results := search:search()
    return
        templates:process($node/node(), $results)
};

declare function matumi:results($node as node()*, $params as element(parameters)?, $model as item()*) {
    search:show-results($model)
};

declare function matumi:facets($node as node()*, $params as element(parameters)?, $model as item()*) {
    let $view := $params/param[@name = "view"]/@value/string()
    return
        <div class="facet-list">
        { search:show-facets($model, $view) }
        </div>
};

declare function matumi:query-form($node as node()*, $params as element(parameters)?, $model as item()*) {
    search:query-form()
};

declare function matumi:browse-boxes($node as node()*, $params as element(parameters)?, $model as item()*) {
    browse:level-boxes()
};

declare function matumi:browse-grid($node as node()*, $params as element(parameters)?, $model as item()*) {
    <div class="grid_16 browse-grid"> 
        { browse:page-grid( false() ) }
     </div>
};

declare function matumi:metadata-combo($node as node()*, $params as element(parameters)?, $model as item()*) {
   let $books := browse-books:data-all( (), (), true()),
       $uri-param := request:get-parameter("uri", () ),
       $uri := if( empty($uri-param )) then document-uri( $books[1] ) else $uri-param,
       $doc := doc($uri)/*,
       $fileDesc := $doc/tei:teiHeader/tei:fileDesc

   return
    <div class="grid_16 entry-view">
     <script>
        $(document).ready(function() {{
            $('#books').live('change', function(event){{
               $('#metadataForm').submit();
            }});
        }});
     </script>
      <form id="metadataForm" action="{if( fn:contains(request:get-url(), '?')) then fn:substring-before(request:get-url(), '?') else request:get-url() }">{
    
       browse:section-parameters-combo( 
             browse-books:titles-list( $books, (),$browse:URIs,() ),
             <level value-names="uri" title="Books" ajax-if-more-then="-1" class="">books</level>,
             false(),
             false()
         ) 
     }</form>
      <div>          
           <table cellspacing="3" cellpadding="3" style="margin-top:1em" width="100%">
             <tr>
                <td class="label" width="17%">Author</td>
                <td></td>
             </tr>
             <tr>
                <td class="label">Editor</td>
                <td>{ fn:string-join($fileDesc/tei:titleStmt/tei:editor, ', ') }</td>
             </tr>             
  
             <tr>
                <td class="label">Title</td>
                <td>
                   <div class="book-title-main" style="font-size:115%">{ fn:string-join( $fileDesc/tei:titleStmt/tei:title[@type="main" or empty(@type) ], ', ' ) }</div>
                   <div class="book-title-sub">{  fn:string-join( $fileDesc/tei:titleStmt/tei:title[@type="sub"], ', ' ) }</div>                
                </td>
             </tr>
             <tr>
                <td class="label">Year</td>
                <td>{ string($fileDesc/tei:publicationStmt/date) }</td>
             </tr>
             <tr>
                <td class="label">Publisher</td>
                <td>{ 
                    $fileDesc/tei:publicationStmt/*                    
                }</td>
             </tr>
             <tr>
                <td class="label">Notes</td>
                <td>{
                     $fileDesc/tei:sourceDesc//tei:notesStmt/tei:note/*
                }</td>
             </tr>
             <tr>
                <td class="label">Articles in this encyclopedia</td>
                <td> <ul id="entries-links">{
                    for $e in $doc/tei:text/tei:body/tei:div[@type="entry"]                    
                    let $title := fn:string-join($e/tei:head, ', ') 
                    return element {'li'}{
                       element a {
                          attribute {'class'}{ 'entry-derect-link' },
                          attribute {'href'}{ concat('entry.html?doc=', document-uri( root($e)), '&amp;node=',util:node-id($e))},    
                          $title
                        }     
                    }
                }</ul></td>
             </tr>

          </table>
     </div>     
  </div>
};

