xquery version "1.0";

module namespace browse-summary="http://exist-db.org/xquery/apps/matumi/browse-summary";

declare namespace anno="http://exist-db.org/xquery/annotate";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare copy-namespaces no-preserve, no-inherit;
declare boundary-space strip;

import module namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace util="http://exist-db.org/xquery/util";
import module namespace system="http://exist-db.org/xquery/system";
import module namespace counter="http://exist-db.org/xquery/counter" at "java:org.exist.xquery.modules.counter.CounterModule";

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace browse="http://exist-db.org/xquery/apps/matumi/browse" at "browse.xqm";
import module namespace browse-data="http://exist-db.org/xquery/apps/matumi/browse-data" at "browse_data.xqm";


(: import module namespace browse-config="http://exist-db.org/xquery/apps/matumi/browse-config" at "browse_config.xqm"; :)

declare variable $browse-summary:base-time := browse-summary:base-time-get(false());

declare function  browse-summary:base-time-get( $update as xs:boolean ) as xs:dateTime{   
   let $coll := concat($config:app-root, '/cache'),
      $file-name := '0000_base-time.xml',
      $uri := concat( $coll, '/', $file-name),
      $existing-base := if( fn:doc-available($uri) ) then doc($uri)/*  else ()      
      
     return  if( exists( $existing-base) and not($update) ) then 
               xs:dateTime($existing-base)
          else (               
              let $ts :=  dateTime(current-date(), util:system-time() ),
              $update :=   
              (:    util:catch("*",  :) 
                  (    
                      xdb:store( $coll, $file-name ,  
                         element {'base-time'}{ $ts }
                      ),                      
                       util:log("INFO", ("Base time ha been changed to  ", $ts )  )
                   )
(:                    , util:log("WARN", ("Failed to update category base time", $uri )  )      :)
                 
           return $ts
         )           
};   


declare function  browse-summary:all( ){   
  let   $uri :=  concat($config:app-root, '/cache/0000_all-categories-summary.xml'),
        $saved-summary := if( fn:doc-available($uri) ) then doc($uri)/*  else ()
        
  return if( exists( $saved-summary ) ) then (: or xs:dateTime($saved-summary/@ts) < $base-time :)
               $saved-summary/category 
          else(
            let $new-summary :=  browse-summary:make(   collection(concat($config:app-root, '/data'))//tei:name[@type], false() ),
                $saved :=  browse-summary:save( (), $new-summary  ) 
            return $new-summary
        )
};   

declare function  browse-summary:get-one( $node as node() ){
     if( number($node/tei:summary/@names) > 0 ) then (
         let $summary := if( $node/tei:summary/@uuid ) then 
                              collection( concat($config:app-root, '/cache'))/categories-summary[ @uuid = $node/summary/@uuid ]/*
                         else ()
                         
         return if( empty($summary) ) then (: or xs:dateTime($summary/@ts) < $base-time :)
                     browse-summary:update-one( $node  )
                else $summary
    )else ()
};

declare function  browse-summary:update-one( $node as node() ){
    let $started-at := dateTime(current-date(), util:system-time() )
    let $new-summary :=  browse-summary:make($node, false() ),                        
        $save := if( local-name($node) = ('TEI','div') ) then 
                     browse-summary:save( $node, $new-summary  )
                 else ()                                
    return $new-summary
};

declare function  browse-summary:get-out-of-entries-only( 
   $QUERIEs as element(query)*,  
   $level as node()?,    
   $URIs as element(URI)*,  
   $Categories as element(category)*, 
   $update as xs:boolean, 
   $embeded as xs:boolean 
 ){
 
    let $Q := $QUERIEs[@name= $level ],
        $data-all := browse-data:strip-query(  $Q/tei:data-all ),
        $data-filtered := browse-data:strip-query(  $Q/tei:data-all )

  return if( $level/@pos = 1 or $data-all[2] = '#all' ) then(  (: cases x.1  or fn:empty( $URIs ) :)
        browse-summary:all()
   )else (
    
    let $nodes-to-process := util:eval($data-all[1]),
        $existing-summary := collection( concat($config:app-root, '/cache'))/categories-summary[ @uuid = $nodes-to-process/summary[number(@names) > 0]/@uuid ]/*,                             
        $nodes-with-missing-summary  := $nodes-to-process[ empty(summary/@uuid) or ( number(summary/@names) > 0 and not(summary/@uuid = $existing-summary/@uuid)) ],
        
        $fresh := for $n at $pos in $nodes-with-missing-summary[ position() <= $browse:max-cat-summary-to-save ]   
                  return browse-summary:update-one( $n )
                       
    let $result := (
        $existing-summary,
        $fresh, 
         browse-summary:make( fn:subsequence($nodes-with-missing-summary, $browse:max-cat-summary-to-save+1 ), false() )
      )  

     return 
       if( count( $nodes-to-process ) > 1 ) then (
             browse-summary:combine( $result, $Categories )
       )else $result
  )
};

declare function  browse-summary:combine( $categories as element(category)*, $Categories as element(category)* ){
     for $name in fn:distinct-values( $categories/@name )
       let $nodes-of-this-type := $categories[@name= $name],
           $keys := fn:distinct-values($nodes-of-this-type//@key)
       order by fn:lower-case($name) 
       return    
          if( fn:count( $nodes-of-this-type) = 1 ) then
             $nodes-of-this-type
          else(
              let $values := 
                 for $k in $keys
                   let $values := $nodes-of-this-type/value[@key = $k]
                   return (
                     if( fn:count( $values ) = 1 ) then
                         $values
                     else 
                    
                     element {'value'}{
                        attribute {'key'}{ $k },
                        attribute {'instances'}{ sum( $values/@instances) },
                        $values[1]/@value-insted-of-key,
                        string($values[1])
                     }
                 )

             return 
               element {'category'}{
                 attribute {'name'}{ $name },
                 attribute {'values'}{ count($keys) },
                 attribute {'instances'}{ sum( $values/@instances ) },
                 $values
              }
     )
}; 

(:

    <category name="instituion" count="0" no-keys="1" total="1">
        <value key="Asiatic Society" value-insted-of-key="yes" count="1" name-node-id="3.2.2.2.4.4.8.128">Asiatic Society*</value>
    </category>

:)

declare function browse-summary:detailes($n as element()* ){   
    $n/summary    
};


declare function  browse-summary:save( $node as node()?, $categories as element(category)*  ){
      let $summary :=  $node/summary[1], 
          $uuid := if( not($node)) then '0000' else ($summary/@uuid, util:uuid())[1],
          $book := if( not($node)) then '*'  else document-uri( root($node)),
          $coll := concat($config:app-root, '/cache'),
          $file-name := if( fn:empty($node)) then '0000_all-categories-summary.xml' else concat('categories_', $uuid, '.xml'),
          $uri := concat( $coll, '/', $file-name)

      return if( fn:doc-available($uri) ) then (   (: or xs:dateTime($saved-summary/@ts) < $base-time :)
          )else(
               let $names-count := count($categories),
                   $values-count := sum($categories/@values),
                   $instances-count :=  sum($categories/@instances)
               
              return (
(:          
              return util:catch("*", ( 
 :)               
         util:eval-async((
               
            system:as-user( request:get-attribute('xquery.user'), request:get-attribute('xquery.password'), (
            
                      if( fn:exists( $categories)) then (
                         xdb:store( $coll, $file-name ,  
                            element {'categories-summary'}{
                              attribute {'names'}{ $names-count }, 
                              attribute {'values'}{ $values-count },   
                              attribute {'instances'}{ $instances-count },
                              attribute {'uuid'}{$uuid },                    
                              attribute {'book'}{ $book },
                              attribute {'ts'}{ dateTime(current-date(), util:system-time() ) },
                              $categories
                           } 
                         ),
                         xdb:set-resource-permissions($coll, $file-name, "editor", "biblio.users", xdb:string-to-permissions( 'rwurwurwu' ))     
                      ) else(),  
                       
                                        
                       if( fn:exists($node) ) then (
                            if( fn:empty($summary) ) then (
                                    update insert 
                                       element {'summary'}{
                                         attribute {'names'}{ $names-count }, 
                                         attribute {'values'}{ $values-count },   
                                         attribute {'instances'}{ $instances-count },
                                         attribute {'uuid'}{ $uuid },
                                         attribute {'ts'}{  dateTime(current-date(), util:system-time() ) }
                                       } 
                                    into $node  (:  Side effect  :)  
                            ) else (
                              if( number($summary/@names)  !=  $names-count )  then update value $summary/@names with $names-count else (),
                              if( number($summary/@values) !=  $values-count ) then update value $summary/@values with $values-count else(),
                              if( number($summary/@instances) !=  $instances-count  ) then update value $summary/@instances with $instances-count  else(),
                              if( number($summary/@names) !=  $names-count or number($summary/@values) !=  $values-count or number($summary/@instances) !=  $instances-count ) then 
                                  update value $summary/@ts  with dateTime(current-date(), util:system-time() )
                              else()
                           )                
                       ) else(   (: this the summary of all books, no node to hold the summary reff :) ),     
                        util:log("INFO", ("Saved categories-summary for ", document-uri( root($node)), ', ', if( fn:exists($node)) then util:node-id( $node ) else() )  )
                    )) 
                    

                  ))   
 (:                 
                ), util:log("WARN", ("Failed to save categories-summary for ", document-uri( root($node)), ', ',if( fn:exists($node)) then util:node-id( $node ) else() )  )
:)                
             ) 
      )
};


declare function  browse-summary:make( $n as element()*, $add-node-id as xs:boolean ) {
   for $name in $n/descendant-or-self::tei:name[@type][@key]
    group $name as $byType by $name/@type as $type
   order by $type  
    return
        let $values :=
            for $name in $byType
            group $name as $byKey by $name/@key as $key
            order by fn:lower-case($key) 
            return
                   let $instances-count := count($byKey)
                   let $keyName := translate(replace($key, "^.*/([^/]+)$", "$1"), "_", " ")
                   return if( $key != '' ) then 
                      element {'value'}{ 
                        attribute {'key'}{ $key },
                        attribute {'instances'}{ $instances-count },
                        if( $add-node-id ) then ( attribute {'name-node-id'}{ util:node-id($byKey[1])} ) else(),
                        fn:string-join((
                               $keyName
                               (: , if( $instances-count > 1 ) then (' (', $instances-count , ')') else ()  :)
                            ),'')                                        
                      }
                    else()
        return
            element category {               
                   attribute {'name'}{$type},
                   attribute {'values'}{ count($values) },
                   attribute {'instances'}{ sum($values/@instances) },
                   $values
            }
};


declare function local:attribute-update ( $atttName as xs:string, $value as item(), $node as node() ) as empty() {
    if( exists($node )) then (
         let $attr := $node/@*[ local-name() = $atttName ]
         return if( exists($attr ) ) then 
               update value $attr with string( $value )
         else  update insert attribute { $atttName } { $value } into $node
     )else ()
};