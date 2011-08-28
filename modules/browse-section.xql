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
    $level := number(request:get-parameter("level", 0 )),
        
(:

function page-304:is-cached-page-still-valid( 
      $ETag as xs:string?,
      $last-modified as xs:dateTime,
      $expiresAfter as xs:dayTimeDuration?, 
      $must-revalidate as xs:boolean
)

:)
     
    $cache := response:set-header( "Cache-Control", 'public, max-age=43200') (: 12h :)
(:    
    , $is-it-cached := browse-cache:is-it-cached( $data-id, , (), false())
    browse-names:titles-list( browse-cache:get-cached-data( $browse:cache, $browse:LEVELS[ @pos  = $level ]/@vector, () ), $browse:LEVELS[ @pos  = $level ], $browse:URIs, $browse:CATEGORIES )
:)

return 
 
  if( $section = 'test') then (
       let $Q := $browse:QUERIES[ @pos= $level ],
        $data-all := browse-data:strip-query(  $Q/tei:data-all ),
        $data-filteres := browse-data:strip-query(  $Q/tei:data-all ),
        $nodes := util:eval($data-all[1])
   
     return 
      element test { 
         $browse:QUERIES,
        (: browse-summary:get-out-of-entries-only( $browse:QUERIES, $browse:LEVELS[@pos = $level], $browse:URIs,  $browse:CATEGORIES, $browse:refresh-categories,  $browse:embeded-category-summary ),  :)
        <test-------------------------------------------/>, 
        $browse:URIs,
        $browse:CATEGORIES,
        $browse:SUBJECTS,
        <test-------------------------------------------/> 

      }
   )else 
 
     if(  request:get-parameter("section", 'none')='level-data-combo' and $level > 0) then (
           local:section-titles-combo(  $browse:LEVELS[$level] )    
           
    )else if( $section = 'entity-grid') then (
    
          let $q := browse-data:strip-query(  $browse:QUERIES[@name= 'grid' ]/tei:data-fitered ),
              $data :=  util:eval( $q[1] )  ,
              $page := number(request:get-parameter("page", 1 )),              
              $page-size := $browse:grid-categories-page-size,
              $total-pages := fn:ceiling( count($data) div $page-size ),
              $in-this-page := fn:subsequence($data, $page-size * ($page - 1) +1  ,$page-size),
              $more := $page < $total-pages
          return 
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
            			      $summary := $e/tei:summary,
            			      $alt-titles := browse-entries:alternative-titles($e),
            			      $categories-number := number( ($summary/@values, browse-names:categories-number($e))[1]) 
            			 
            			 return <tr class="{ if( $tr-pos mod 2 = 0 ) then 'odd' else ()}">{
            				<td >{ string($document-title)}</td>,
            				<td  >{
                       				browse-entries:direct-link($e), 
            				        if( exists($alt-titles)) then concat(' (', fn:string-join( $alt-titles , ', '), ')') else() }</td>,
            				<td>{ 
            				   if( fn:exists( $e/@subtype )) then 
            				      local:capitalize-first($e/@subtype )
            				   else '-'
            				 }</td>,
            				<td class="cat-container collapsed" >{  
            				 
          				  if( $categories-number  = 0 and fn:exists($summary/@values ) ) then( 
            				      (:  no categories :) '-'
            				  )else

                               if( fn:empty( $summary/@values ) or (fn:exists($summary/@values ) and number( $summary/@values )  >  $browse:grid-categories-ajax-trigger ) ) then (
                                     let $url := browse:ajax-url( (), (
                                                          concat('node-id=',  util:node-id($e) ), 
                                                          concat('cat-entry-uri=',   document-uri( root($e)) ),
                                                          concat('cat2get=', $summary/@values   ),                                                      
                                                          'section=entry-cat-summary',
                                                          concat( 'id=td', $tr-pos ) 
                                                  ), $browse:controller-url, $browse:LEVELS)               	     
                  			        return <div id="td{$tr-pos}" class="cat-container collapsed ajax-loaded loading-red" url="{$url}">Loading  { if( exists($summary/@values) ) then string($summary/@values) else '' } categories </div>           				       
            				  )else (
                 				    browse-names:entiry-categories-listed( $e )
                              ) 
            				}</td>
            			}</tr>
            			
            	    }</tbody>
            	</table>
                 
              )                 
  
    )else if( $section = 'entry-cat-summary') then (   
         browse-names:entiry-categories-listed(                 
            util:node-by-id(
                 doc(request:get-parameter("cat-entry-uri", 'none') ), 
                 request:get-parameter("node-id", '1.0')
           )        
        )
       
    )else <div class="ajax-missing-section">Unknown section "{ $section }"</div>
  
