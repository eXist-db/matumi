xquery version "1.0";

declare namespace anno="http://exist-db.org/xquery/annotate";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare copy-namespaces no-preserve, no-inherit;
declare boundary-space strip;

declare option exist:serialize "method=xml media-type=text/xml omit-xml-declaration=yes indent=yes";


(: import module namespace browse-cache="http://exist-db.org/xquery/apps/matumi/cache" at "browse_cache.xqm"; 
import module namespace browse-entries="http://exist-db.org/xquery/apps/matumi/browse-entries" at "browse_entries.xqm";
import module namespace cache="http://exist-db.org/xquery/cache" at "java:org.exist.xquery.modules.cache.CacheModule";
import module namespace counter="http://exist-db.org/xquery/counter org.exist.xquery.modules.counter.CounterModule";

:)
import module namespace browse="http://exist-db.org/xquery/apps/matumi/browse" at "browse.xqm";
import module namespace browse-books="http://exist-db.org/xquery/apps/matumi/browse-books" at "browse_books.xqm";
import module namespace browse-entries="http://exist-db.org/xquery/apps/matumi/browse-entries" at "browse_entries.xqm";
import module namespace browse-subject="http://exist-db.org/xquery/apps/matumi/browse-subject"  at "browse_subject.xqm";
import module namespace browse-names="http://exist-db.org/xquery/apps/matumi/browse-names" at "browse_names.xqm";
import module namespace browse-data="http://exist-db.org/xquery/apps/matumi/browse-data" at "browse_data.xqm";
import module namespace browse-summary="http://exist-db.org/xquery/apps/matumi/browse-summary" at "browse_summary.xqm";
import module namespace page-304="http://exist-db.org/xquery/page-304-status" at "page-304-status.xqm";

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";


declare function local:capitalize-first($str as xs:string) as xs:string {
    concat(upper-case(substring($str,1,1)), substring($str,2))
 };

declare function local:section-titles-combo(  $level as node()? ) {
   let $titles := 
            if( $level = 'books')   then  browse-books:titles-list-fast(   $browse:QUERIES, $level, $browse:URIs, $browse:CATEGORIES )            
       else if( $level = 'entries') then  browse-entries:titles-list-fast( $browse:QUERIES, $level, $browse:URIs, $browse:CATEGORIES )
       else if( $level = 'names')   then  browse-names:titles-list-fast(   $browse:QUERIES, $level, $browse:URIs, $browse:CATEGORIES )    
       else if( $level = 'subjects') then  browse-subject:titles-list-fast($browse:QUERIES, $level, $browse:URIs, $browse:CATEGORIES, $browse:SUBJECTS )    
       else  <titles><title>no-titles for level { $level }</title></titles>			
 
    return if( exists($titles)) then ( 
               browse:section-parameters-combo( $titles, $level, true(), true() )
           ) else ()
};
 
let $section := request:get-parameter("section", 'none'),
    $cache-id := request:get-parameter("cache", 'none'),   
    $level := number(request:get-parameter("level", 1 ))
(:
    $cache := response:set-header( "Cache-Control", 'public, max-age=43200') (: 12h :)
:)

return 
 
  if( $section = 'test') then (
       let $Q := $browse:QUERIES[ @pos= $level ] 
     return 
      element test { 
          <saved>{ browse:list-saved-parameters() }</saved>,
          <L1> { browse:get-parameter('L1', ()) } </L1>,
         (: $browse:QUERIES, :)
          $browse:URIs, 
          $browse:CATEGORIES
      }
   )else 
 
     if(  request:get-parameter("section", 'none')='level-data-combo' and $level > 0) then (
          let $Q := $browse:QUERIES[ @pos= $level ],
               $etag := $Q/tei:data-all/tei:etag,
               $isAll := fn:starts-with($etag, 'all-')  
         
          return if( $isAll) then (
                let $last-modified := if( $etag = ('all-entries-1', 'all-books-1', 'all-subjecs-1')  ) then (
                                      page-304:last-modified( collection( concat($config:app-root, '/data'))/tei:TEI )
                                )else if ( $etag = 'all-names-1' ) then (
                                      xmldb:last-modified(    concat($config:app-root, '/cache'), 'categories-all.xml' )   
                                )else ()                                      
               
                return if( fn:empty ($last-modified) ) then (
                           local:section-titles-combo(  $browse:LEVELS[$level] )  
                       )else if (not(page-304:is-cached-page-still-valid( $etag,  $last-modified, $browse:http-cache,  true())) ) then  
                          local:section-titles-combo(  $browse:LEVELS[$level] )   
                      else  <same/> 
          )else(
                local:section-titles-combo(  $browse:LEVELS[$level] )    
          )
     
(:     
         $last-modified := page-304:last-modified( $summary )
             
         return if( fn:exists($summary) and page-304:is-cached-page-still-valid( $summary/@uuid,  $last-modified, xs:dayTimeDuration( "PT12H" ),  true()) ) then (                
                )else(
                    browse-names:entiry-categories-listed( $entry, $summary/* )                
                )
:)
           
           
    )else if( $section = 'entity-grid') then (
    
          let $Q := $browse:QUERIES[@name= 'grid' ],           
              $data := util:eval($Q/tei:data-filtered/tei:query  ), 
              $page := number(request:get-parameter("page", 1 )),              
              $page-size := $browse:grid-categories-page-size,
              $total-pages := fn:ceiling( count($data) div $page-size ),
              $first-row   := $page-size * ($page - 1),
              $in-this-page := fn:subsequence($data, $first-row +1  ,$page-size),              
              $more := $page < $total-pages,
              $last-modified := page-304:last-modified( $in-this-page ),
              $XML-ids := $in-this-page/@xml:id,
              $ETag := if( true() or count($XML-ids) = count( $in-this-page )) then fn:replace(fn:string-join( $in-this-page/@xml:id, ''),'-','') else (),
              $dummy := if( false() and $ETag ) then (
                  response:set-header( "ETag", $ETag ),
                  response:set-header( "Last-Modified",  datetime:format-dateTime( $last-modified, 'EEE, d MMM yyyy HH:mm:ss Z' ))
              )else()
              
          return if( page-304:is-cached-page-still-valid( $ETag,  $last-modified, $browse:http-cache,  true()) ) then (             
          
            )else (
              if( $page > $total-pages ) then 
                   <div id="noMoreData" noMoreData="yes" class="noMoreData">no more data</div>
              else (
               
               	<table id="entryGrid" class="browse-tbl" summary="Table summary" cellspacing="4" >
             	  {  if( not($more) ) then attribute {'noMoreData'}{'yes'} else()  }
            		<colgroup>
            			<col class="colA" width="20%"/>
            			<col class="colB" width="25%"/>
            			<col class="colC"/>
            			<col class="colD" width="45%" />
            		</colgroup>
            		<thead>
            			<tr>
            				<th>Encyclopedia</th>
            				<th>Entry Title</th>        				
            				<th>Subject</th>
            				<th width="45%">Categories</th>
            			</tr>
            		</thead>
            		<tbody>{
            			 for $e at $tr-pos in $in-this-page
                          let $root := $e/ancestor-or-self::tei:TEI,
            			      $uri  := document-uri( root($e)),
            			      $document-title := browse-books:title-extract( $e//tei:fileDesc/tei:titleStmt, $root, $browse:URIs),
            			      $node-id := util:node-id($e),
            			      $alt-titles := browse-entries:alternative-titles($e),
            			      $sum-values := browse-summary:value-numbers($e),
            			      $categories-number := xs:long( if( fn:exists( $sum-values )) then $sum-values else browse-names:categories-number($e) ),
            			      $td-dom-id := concat( 'td', ($first-row + $tr-pos) )
            			 
            			 return 
            			  <tr class="{ if( $tr-pos mod 2 = 0 ) then 'odd' else ()}">
               				<td>{ string($document-title)}</td>
               				<td>{
                          		       browse-entries:direct-link($e), 
               				       if( exists($alt-titles)) then concat(' (', fn:string-join( $alt-titles , ', '), ')') else() 
               				}</td>
               				<td>{ 
               				   if( fn:exists( $e/@subtype )) then 
               				      local:capitalize-first($e/@subtype )
               				   else '-'
               				 }</td>
               				 <td class="cat-container collapsed" >{               				 
               				      if( $categories-number  = 0 and fn:exists($sum-values ) ) then( 
                 				      (:  no categories :) '-'
                 				  )else if( $categories-number  >  $browse:grid-categories-ajax-trigger  ) then (
                                         let $url := browse:ajax-url( (), (
                                                               concat('node-id=',  util:node-id($e) ), 
                                                               concat('cat-entry-uri=',   document-uri( root($e)) ),
                                                               concat('cat2get=', $sum-values   ),                                                      
                                                               'section=entry-cat-summary',
                                                               concat( 'id=', $td-dom-id ) 
                                                       ), $browse:controller-url, $browse:LEVELS)               	     
                       			        return <div id="{$td-dom-id}" class="cat-container collapsed ajax-loaded loading-red" url="{$url}">Loading  { if( exists($sum-values) ) then string($sum-values) else '' } categories </div>           				       
                 				  )else (
                      			   browse-names:entiry-categories-listed( $e, () )
                                 ) 
               				 }</td>
            			  </tr>
            			 
            	    }</tbody>
            	</table>
            	
            	
               )  
              )                 
  
    )else if( $section = 'entry-cat-summary') then (   
         let $uri := request:get-parameter("cat-entry-uri", 'none'),
             $entry := util:node-by-id( doc($uri),   request:get-parameter("node-id", '1.0') ),
             $summary := browse-summary:get-many-packed( $entry ),          
             $last-modified := page-304:last-modified( $summary )
             
         return if( fn:exists($summary) and page-304:is-cached-page-still-valid( $summary/@uuid,  $last-modified, xs:dayTimeDuration( "PT12H" ),  true()) ) then (                
                )else(
                    browse-names:entiry-categories-listed( $entry, $summary/* )                
                )
       
    )else <div class="ajax-missing-section">Unknown section "{ $section }"</div>
  
