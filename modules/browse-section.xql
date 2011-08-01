xquery version "1.0";

declare namespace anno="http://exist-db.org/xquery/annotate";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare copy-namespaces no-preserve, no-inherit;
declare boundary-space strip;

declare option exist:serialize "method=xml media-type=text/xml omit-xml-declaration=yes indent=yes";

import module namespace browse="http://exist-db.org/xquery/apps/matumi/browse" at "browse.xqm";
import module namespace browse-names="http://exist-db.org/xquery/apps/matumi/browse-names" at "browse_names.xqm";

import module namespace cache="http://exist-db.org/xquery/cache" at "java:org.exist.xquery.modules.cache.CacheModule";

let $section := request:get-parameter("section", 'none'),
    $data-id   := request:get-parameter("cache", 'none')
   
(: let $data  := cache:remove( $browse:cache, $data-id  ) :)
let $level := number(request:get-parameter("level", 0 ))

let $LEVELS :=      $browse:LEVELS
let $URLs : =       $browse:URIs 
let $CATEGORIES : = $browse:CATEGORIES 

(:
    $LEVELS,
    $URLs,
    $CATEGORIES
    
    
    util:declare-option("exist:serialize", "method=xml media-type=text/xml indent=yes") 
    
    declare option exist:serialize "media-type=text/json";
    
:)

return (
     if(  request:get-parameter("section", 'none')='level-data-combo' and $level > 0) then (
          let $data := browse:get-cached-data( $browse:LEVELS[ @pos  = $level ]/@vector, () )          
          
          return if( 'yes' = request:get-parameter("json", 'no')) then (
                 browse:section-titles-combo-as-json(  $data, $LEVELS[$level] )
            )else(
                  browse:section-titles-combo(  $data, $LEVELS[$level] )
            )
      
    )else if( $section = 'entity-grid') then (
          let $data := browse:get-cached-data( $browse:LEVELS[ .  = 'entries' ]/@vector, '-grid')
          return (
              browse:page-grid( true(), false(), $data  )
          )
  
    )else if( $section = 'entry-cat-summary') then (
        
        browse-names:entiry-categories-listed(                 
            util:node-by-id(
                 doc(request:get-parameter("cat-entry-uri", 'none') ), 
                 request:get-parameter("node-id", '1.0')
           ),
           true()           
        )
       
    )else <div class="ajax-missing-section">Unknown section "{ $section }"</div>
  
)