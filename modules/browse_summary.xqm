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

declare function local:now() as xs:dateTime {   dateTime(current-date(), util:system-time() ) };

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


declare function  browse-summary:add-books-id( ) {    
     system:as-user( $config:credentials[1], $config:credentials[2], (     
         for $book at $pos in collection ( concat($config:app-root, '/data') )/tei:TEI[ empty(@xml:id) ] 
         return update insert attribute {  xs:QName("xml:id") }{ concat('i',$pos)} into $book         
     ))
};     

declare function browse-summary:next-id( $node as node()   ) {    
     let $book :=  document-uri( root($node) ),
         $top  :=  $node/ancestor-or-self::tei:TEI,
         $this-book-id := if( exists($top/@xml:id)) then 
                             $top/@xml:id
                          else(
                             browse-summary:add-books-id(), 
                             $top/@xml:id
                          )
                     
     return if( local-name( $node ) = 'TEI') then 
               $this-book-id
         else (
              let $next := counter:next-value( $book ),   
                  $next-id := if( $next = -1 ) then (          
                                   counter:create( $book, xs:long( fn:max((100, for $i in $node/ancestor-or-self::tei:TEI//@xml:id 
                                                                                let $id := if( fn:contains($i, '-') ) then fn:substring-after($i, '-') else ()
                                                                                return if( $id ) then xs:long( $id) else ()
                                                                          )) 
                                                 ))        
                              )else $next   
             return concat($this-book-id, '-', $next-id)
         )
       
};

declare function  browse-summary:all( ){   
  let   $uri :=  concat($config:app-root, '/cache/categories-all.xml'),
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
     if( empty($node/@xml:id) ) then (: or xs:dateTime($summary/@ts) < $base-time :)
          browse-summary:update-one( $node  )
     else collection( concat($config:app-root, '/cache'))/categories-summary[ @uuid = $node/@xml:id ]/*
};

declare function  browse-summary:get-many-packed( $nodes as node()* ){
     collection( concat($config:app-root, '/cache'))/categories-summary[ @uuid = $nodes/@xml:id ]
};

declare function  browse-summary:value-numbers( $node as node()? ){
     collection( concat($config:app-root, '/cache'))/categories-summary[ @uuid = $node/@xml:id ]/@values
};


declare function  browse-summary:update-one( $node as node() ){
    let $started-at := dateTime(current-date(), util:system-time() )
    let $new-summary :=  browse-summary:make($node, false() ),                        
        $save := if( true() and local-name($node) = ('TEI','div') ) then 
                     browse-summary:save( $node, $new-summary  )
                 else ()                                
    return $new-summary
};

declare function  browse-summary:get-out-of-entries-only( 
   $QUERIEs as element(query)*,  
   $level as node()?,    
   $URIs as element(URI)*,  
   $Categories as element(category)* 

 ){
 
  let $Q := $QUERIEs[@name= $level ]

  return if( $level/@pos = 1 or $Q/tei:data-all/tei:summary/@type = 'all' ) then(  (: cases x.1  or fn:empty( $URIs ) :)
        browse-summary:all()
   )else (
    let $nodes-to-process := if( $Q/tei:data-all/tei:summary/@type = 'book' ) then (
                  for $uri in $Q/tei:data-all/tei:summary[@type = 'book']
                  return  doc($uri)/* 
              )else browse-data:execute-query( $Q ),
        $coll := concat($config:app-root, '/cache'),         
         
        $existing-summary := collection( $coll )/categories-summary[ @uuid = $nodes-to-process/@xml:id ]/*, 
        $nodes-with-missing-summary  := $nodes-to-process[ empty(@xml:id) or not(@xml:id = collection( $coll )/categories-summary/@uuid )],        
        $fresh := for $n at $pos in $nodes-with-missing-summary[ position() <= $browse:max-cat-summary-to-save ]   
                  return browse-summary:update-one( $n )
                       
    let $result := (
        $existing-summary,
        $fresh, 
         browse-summary:make( fn:subsequence($nodes-with-missing-summary, $browse:max-cat-summary-to-save+1 ), false() )
      ) 
      
     return (
       
       if( count( $nodes-to-process ) > 1 ) then (
             browse-summary:combine( $result, $Categories )
       )else $result
     )
  )
};

(:
declare function browse-summary:detailes($node as element()* ){   
   if( exists( $node/@xml:id )) then    
       $node/ancestor-or-self::tei:TEI/tei:summary[@uuid = $node/@xml:id ]
   else ()       
};
:)

declare function  browse-summary:save( $node as node()?, $categories as element(category)*  ){
      let $root := root($node),
          $node-id := $node/@xml:id,
          
          $uuid := if( not($node)) then 
                       '0000' (: summary of all :)
                   else if( fn:exists($node/@xml:id)) then
                        string( $node/@xml:id )
                   else browse-summary:next-id($node),
                   
          $book := if( not($node)) then 'all.xml'  else document-uri( $root ),
          $coll := concat($config:app-root, '/cache'),
          $file-name := if( fn:empty($node)) then 'categories-all.xml' else concat('categories_', fn:substring-before( util:document-name($node)  ,'.xml'), '_', $uuid, '.xml'),
          $uri := concat( $coll, '/', $file-name)

      return if( fn:doc-available($uri) ) then (   (: or xs:dateTime($saved-summary/@ts) < $base-time :)
          )else(
               let $names-count := count($categories),
                   $values-count := sum($categories/@values),
                   $instances-count :=  sum($categories/@instances)
               
              return (
             (:     util:eval-async(           :)     
                     system:as-user( $config:credentials[1], $config:credentials[2], (            
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
                             xdb:set-resource-permissions($coll, $file-name, $config:credentials[1], $config:group, xdb:string-to-permissions( 'rwurwurwu' )),     
                                             
                            if( fn:exists($node) and empty( $node/@xml:id ) ) then (
                                    update insert attribute {   xs:QName("xml:id") }{ $uuid } into $node
                            ) else()                        
                       ))                      
              (:  ) :)
            )
      )
      
};

declare function  browse-summary:combine( $categories as element(category)*, $Categories as element(category)* ){
 for $category in $categories
    group $category as $byName by $category/@name as $cat-name
    order by fn:lower-case($cat-name) 
    return   
    
        let $values :=            
   
         for $value in $byName/value
            group $value as $byKey by $value/@key as $key
            order by fn:lower-case($key) 
            return           
                   let $instances-count := count($byKey)
                   let $keyName := translate(replace($key, "^.*/([^/]+)$", "$1"), "_", " ")
                   return if( $key != '' ) then 
                      element {'value'}{ 
                        attribute {'key'}{ $key },
                        attribute {'instances'}{ $instances-count },
                        $keyName
                      }
                    else()
        return
            element category {               
                   attribute {'name'}{ $cat-name},
                   attribute {'values'}{ count($values) },
                   attribute {'instances'}{ sum($values/@instances) },
                   $values
            }
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