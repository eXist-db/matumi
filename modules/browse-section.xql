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

import module namespace browse-summary="http://exist-db.org/xquery/apps/matumi/browse-summary" at "browse_summary.xqm";

:)

import module namespace browse="http://exist-db.org/xquery/apps/matumi/browse" at "browse.xqm";
import module namespace browse-names="http://exist-db.org/xquery/apps/matumi/browse-names" at "browse_names.xqm";
import module namespace browse-data="http://exist-db.org/xquery/apps/matumi/browse-data" at "browse_data.xqm";


let $section := request:get-parameter("section", 'none'),
    $cache-id := request:get-parameter("cache", 'none'),   
    $level := number(request:get-parameter("level", 0 )),
        
      (:  <info data="" ts="" expires-at=""/> 
        
    $cached-info := browse-cache:cached-info($cache-id),
    $data-id := $cached-info/@data,  (: should be the same as $browse:LEVELS[ @pos  = $level ]/@vector :)
    $ts      :=  $cached-info/@ts,
    $expires-at :=  $cached-info/@expires-at,       
     :)
     
    $cache := response:set-header( "Cache-Control", 'public, max-age=43200') (: 12h :)
(:    
    , $is-it-cached := browse-cache:is-it-cached( $data-id, , (), false())
    browse-names:titles-list( browse-cache:get-cached-data( $browse:cache, $browse:LEVELS[ @pos  = $level ]/@vector, () ), $browse:LEVELS[ @pos  = $level ], $browse:URIs, $browse:CATEGORIES )
:)

return 
 
  if( $section = 'test') then (
      element test { 
        browse-data:queries-for-all-levels( $browse:LEVELS, $browse:URIs, $browse:CATEGORIES, $browse:SUBJECTS ),     
        <test-------------------------------------------/>,        
        
        $browse:URIs,
        $browse:CATEGORIES,
        $browse:SUBJECTS  
      }
   )else 
   
(:
    if( $data-id != $browse:LEVELS[ @pos  = $level ]/@vector ) then (
        $cached-info,
        $browse:LEVELS[ @pos  = $level ]   
    
    )else
:)
  
     if(  request:get-parameter("section", 'none')='level-data-combo' and $level > 0) then (
           browse:section-titles-combo(  $browse:LEVELS[$level] )                
    )else if( $section = 'entity-grid') then (
          let $data := browse:entries-fast( 'grid' ),
(:          browse-cache:get-cached-data( $browse:cache, $browse:LEVELS[ .  = 'entries' ]/@vector, '-grid'),  :)
              $page := number(request:get-parameter("page", 1 )),
              
              $page-size := $browse:grid-categories-page-size,
              $total-pages := fn:ceiling( count($data) div $page-size )
          return 
              if( $page > $total-pages ) then 
                   <div id="noMoreData" noMoreData="yes" class="noMoreData">no more data</div>
              else browse:page-grid( true(), false(), fn:subsequence($data, $page-size * ($page - 1) +1  ,$page-size), $page < $total-pages  )          
  
    )else if( $section = 'entry-cat-summary') then (   
         browse-names:entiry-categories-listed(                 
            util:node-by-id(
                 doc(request:get-parameter("cat-entry-uri", 'none') ), 
                 request:get-parameter("node-id", '1.0')
           )        
        )
       
    )else <div class="ajax-missing-section">Unknown section "{ $section }"</div>
  
