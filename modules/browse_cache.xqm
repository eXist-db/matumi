xquery version "1.0";

module namespace browse-cache="http://exist-db.org/xquery/apps/matumi/cache";

declare namespace anno="http://exist-db.org/xquery/annotate";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";

import module namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace util="http://exist-db.org/xquery/util";
import module namespace datetime = "http://exist-db.org/xquery/datetime";
import module namespace cache="http://exist-db.org/xquery/cache" at "java:org.exist.xquery.modules.cache.CacheModule";
import module namespace context="http://exist-db.org/xquery/context" at "java:org.exist.xquery.modules.context.ContextModule";

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

declare function browse-cache:check-cached-data( $minutes-to-cache ){    
   let $expire-at := dateTime(current-date(), util:system-time() ) + xs:dayTimeDuration( concat('PT', $minutes-to-cache , 'M')),  
       $coll := concat($config:app-root, "/cache"),
       $name := '0000_session-ids.xml',
       $uri := concat($coll, '/', $name), 
       $ping := if(  not(doc-available($uri )) ) then (
                    util:catch("*", 
                       xdb:store( $coll,  $name, <sessions/> ),               
                       util:log("WARN", ("Failed to create", $uri))  
                    )
               ) else (),
       $sessions := doc($uri )/*,
       $this-session := $sessions/tei:session[@id = session:get-id()],
       $now := dateTime(current-date(), util:system-time() ),
       $update-expiration := 
        util:catch("*", (   
               if( exists( $this-session ) )then
                    update value $this-session/@expire with $expire-at 
               else update insert  <session id="{session:get-id()}" expire="{$expire-at}"/>  into $sessions
             
               ,for $i in $sessions/tei:session[ xs:dateTime(@expire) < $now ]
               return (
                   cache:clear( $i/@id ),  (: clear the cache for the expired sessions :)
                   update delete $i
               )
            ),  
            util:log("WARN", ("Failed to update", $uri))   
        )    
   return ()
};



declare function browse-cache:cached-info( $vector as xs:string ){ 
     let $cached := session:get-attribute($vector),
         $parts  := if( empty($cached)) then () else fn:tokenize($cached, '__')
         
     return if( fn:empty($parts)) then () 
            else <info ts="{ $parts[2] }" expires-at="{ $parts[3]  }" data="{ $parts[1] }" />
};


declare function browse-cache:save( $cache-obj, $data as node()*, $vector as xs:string, $suffix as xs:string?, $level-uuid as xs:string ) {
     let $ts := dateTime(current-date(), util:system-time()),
         $expires-at := $ts + xs:dayTimeDuration('PT20M'), 
         $key := fn:string-join(($vector, $suffix), '-')
     
     return (
         cache:put($cache-obj , $key, $data),
         session:set-attribute($level-uuid, concat($key, '__', $ts, '__', $expires-at)   ),  (: used to retreeve the data by AJAX and to check the time and return Status 304 if data is OK :)
         session:set-attribute($key,        concat( $level-uuid, '__', $ts, '__', $expires-at) ) (: used retreeve uuid when $browse:LEVELS is prepared :)
     )
};
declare function browse-cache:get-cached-data( $cache-obj, $key as xs:string, $suffix as xs:string? ) {
    cache:get($cache-obj, fn:string-join(($key, $suffix), '-'))
};

declare function  browse-cache:is-it-cached( 
      $ETag as xs:string,
      $last-modified as xs:dateTime,
      $expiresAfter as xs:dayTimeDuration?, 
      $must-revalidate as xs:boolean
) { 
     let $if-modified-since := request:get-header('If-Modified-Since')
     let $expire-after  := if( empty($expiresAfter) ) then  xs:dayTimeDuration( "PT12H" ) else $expiresAfter (: "P1D"   1 Day expiry period :)     
    
     return if( ( request:get-header('If-None-Match') = $ETag ) or (:  ETag :)
                (fn:string-length($if-modified-since) > 0 and datetime:parse-dateTime( $if-modified-since, 'EEE, d MMM yyyy HH:mm:ss Z' ) <= $last-modified ) 
            ) then (                              
                 let $dummy := (
                        response:set-status-code( 304 ),
                        response:set-header( "Cache-Control", concat('public, max-age=', $expire-after div xs:dayTimeDuration('PT1S')  )) (:   24h=86,400  , must-revalidate :)
                        )
                 return true()
            ) else (                      
                 let $maxAge := $expire-after  div xs:dayTimeDuration('PT1S')
                 let $headers := (                          
                      response:set-header( "ETag", $ETag ),
                      response:set-header( "Last-Modified",  datetime:format-dateTime( $last-modified, 'EEE, d MMM yyyy HH:mm:ss Z' )),
                      response:set-header( "Expires",        datetime:format-dateTime( dateTime(current-date(), util:system-time()) + $expire-after, 'EEE, d MMM yyyy HH:mm:ss Z' )), 
                      response:set-header( "Cache-Control", concat( 'public, max-age=', $maxAge,  if( $must-revalidate ) then ', must-revalidate' else '' ))
                  )
                 return false()
            ) 

                                          
};

