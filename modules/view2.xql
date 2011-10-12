xquery version "1.0";

import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xql";

declare option exist:serialize "method=html5 media-type=text/html";

declare variable $modules :=
    <modules>
        <module prefix="config" uri="http://exist-db.org/xquery/apps/config" at="config.xql"/>
        <module prefix="matumi" uri="http://www.asia-europe.uni-heidelberg.de/xquery/matumi" at="entry-view.xql"/>
    </modules>;


let $content := request:get-data()
(:let $log := util:log("DEBUG", ($content)):)

let $no-cache := if( request:get-parameter( 'resource','something-else') = 'browse.html') then (
                      response:set-header( "Cache-Control",  'no-cache, no-store, max-age=0, must-revalidate' ),
                      response:set-header( "X-Content-Type-Options", 'nosniff' )
                 )else()

return
    templates:apply($content, $modules, ())