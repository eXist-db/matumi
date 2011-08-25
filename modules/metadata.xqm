module namespace metadata="http://exist-db.org/xquery/apps/matumi/metadata";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace browse-books="http://exist-db.org/xquery/apps/matumi/browse-books" at "browse_books.xqm";
import module namespace browse="http://exist-db.org/xquery/apps/matumi/browse" at "browse.xqm";

declare function metadata:all($node as node()*, $params as element(parameters)?, $model as item()*) {
   let $books := browse-books:data-all( (), (), true()),
       $uri := ( request:get-parameter("uri", () ), document-uri( $books[1] ))[1],
       $doc := doc($uri)/*, 
       $fileDesc := $doc/tei:teiHeader//tei:fileDesc,
       $biblFull := $doc/tei:teiHeader//tei:biblFull,
       $sourceDesc :=  $doc/tei:teiHeader/tei:sourceDesc       

   return
    <div class="grid_16 entry-view">

     <script>
        $(document).ready(function() {{
            $('#books').live('change', function(event){{
               $('#metadataForm').submit();
            }});
           $('ul.editions').makeacolumnlists({{cols:4,colWidth:0,equalHeight:true}});
        }});        
     </script>
      <form id="metadataForm" action="{if( fn:contains(request:get-url(), '?')) then fn:substring-before(request:get-url(), '?') else request:get-url() }">{
    
       browse:section-parameters-combo( 
             browse-books:titles-list( $books, (), $browse:URIs,() ),
             <level value-names="uri" title="Books" ajax-if-more-then="-1" class="">books</level>,
             false(),
             false()
         ) 
     }</form>
    
      <div> 
          <h2>Bibliographical Data</h2>      
           <table class="metadata" cellspacing="3" cellpadding="3"  width="100%">
             <tr>
                <td class="label">Title</td>
                <td>
                   <div class="book-title-main" style="font-size:115%">{  $biblFull/tei:titleStmt/tei:title/text()  }</div>
                </td> 
             </tr>
             <tr>
                <td class="label" width="17%">Date</td><td>{ $biblFull/tei:editionStmt/tei:date/text() }</td>
             </tr>
             <tr>
                <td class="label" width="17%">Edition</td><td>{ $biblFull/tei:editionStmt/tei:edition/text() }</td>
             </tr>
             <tr valign="top">
                <td class="label" width="17%">Other editions</td><td>
                    <ul class="editions">{
                       for $n in $biblFull/tei:notesStmt/tei:note
                       return <li>{ $n/text() }</li>                      
                
                   }</ul>
                </td>
             </tr>   
          
             <tr>
                <td class="label" width="17%">Author</td><td>{ $biblFull/tei:titleStmt/tei:author/text()} </td>
             </tr>
             <tr>
                <td class="label">Editor</td>
                <td>{ fn:string-join($biblFull/tei:titleStmt/tei:editor, ', ') }</td>
             </tr>             
  
             <tr>
                <td class="label">Publisher</td>
                <td>{ 
                      $biblFull/tei:publicationStmt/tei:publisher/text()                    
                }</td>
             </tr>
             <tr>
                <td class="label">Physical Description</td>
                <td>{ 
                      $sourceDesc/tei:msDesc/tei:physDesc/tei:p
                }</td>
             </tr>
              <tr>
                <td class="label">Content</td>
                <td>{
                     $sourceDesc/tei:msDesc/tei:msContents/tei:p
                }</td>
             </tr>         
             
             <tr>
                <td class="label">Notes</td>
                <td>{
                     $fileDesc/tei:sourceDesc//tei:notesStmt/tei:note/*
                }</td>
             </tr>
             
             <tr>
                <td class="label">Ready up to here </td>
                <td> -----------------------------------------------------------------------------------------------------  </td>
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

