xquery version "1.0";
module namespace page-304="http://exist-db.org/xquery/page-304-status";

import module namespace datetime = "http://exist-db.org/xquery/datetime";
import module namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace util="http://exist-db.org/xquery/util";

declare function page-304:last-modified( $nodes as node()* ){
    let $nodes2 := ( () | (for $n in $nodes return root($n)) )
    let $dates := for $node in $nodes2                    
                  let $d := xmldb:last-modified(   util:collection-name( $node ), util:document-name( $node ) )
                  order by $d descending
                  return $d

    return $dates[1]
};


declare function page-304:is-cached-page-still-valid( 
      $ETag as xs:string?,
      $last-modified as xs:dateTime,
      $expiresAfter as xs:dayTimeDuration?, 
      $must-revalidate as xs:boolean
) { 
     let $if-modified-since := request:get-header('If-Modified-Since')
     let $expire-after  := if( empty($expiresAfter) ) then  xs:dayTimeDuration( "PT12H" ) else $expiresAfter (: "P1D", "PT12H"  :)   
    
     return 
       if( ( fn:string-length($ETag) > 0 and request:get-header('If-None-Match') = $ETag ) or 
           ( fn:string-length($if-modified-since) > 0 and 
             fn:exists( $last-modified ) and
             datetime:parse-dateTime( $if-modified-since, 'EEE, d MMM yyyy HH:mm:ss Z' ) >= $last-modified 
           ) 
        ) then (                              
             let $dummy := (
                    response:set-status-code( 304 ),
                    response:set-header( "Cache-Control", concat('public, max-age=', $expire-after div xs:dayTimeDuration('PT1S')  )) (:   24h=86,400  , must-revalidate :)
                 )
             return true()
        ) else (                      
             let $maxAge := $expire-after  div xs:dayTimeDuration('PT1S')
             let $headers := (                          
                  if( fn:string-length($ETag) > 0 ) then response:set-header( "ETag", $ETag ) else(),                  
                  response:set-header( "Last-Modified",  datetime:format-dateTime( $last-modified, 'EEE, d MMM yyyy HH:mm:ss Z' )),
                  response:set-header( "Expires",        datetime:format-dateTime( dateTime(current-date(), util:system-time()) + $expire-after, 'EEE, d MMM yyyy HH:mm:ss Z' )), 
                  response:set-header( "Cache-Control",  concat( 'public, max-age=', $maxAge,  if( $must-revalidate ) then ', must-revalidate' else '' ))
              )
             return false()
       )                                         
};

