(:~
    Render a document for display
:)
xquery version "1.0";

declare namespace anno="http://exist-db.org/xquery/annotate";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";

import module namespace func="http://exist-db.org/encyclopedia/functions" at "func.xql";
import module namespace dict="http://exist-db.org/xquery/dict" at "dict2html.xql";
import module namespace jquery="http://exist-db.org/xquery/jquery" at "resource:org/exist/xquery/lib/jquery.xql";

declare option exist:serialize "method=xhtml media-type=text/html add-exist-id=all indent=no omit-xml-declaration=yes";

let $resource := request:get-parameter("doc", ())
let $query := request:get-parameter("q", ())
let $context := doc($resource)
let $root :=
    if ($query) then
        let $result := util:eval($query)
        return
            $result/ancestor-or-self::tei:TEI
    else
        $context
let $ajax := request:get-parameter('ajax', ())
return
    (: If called from javascript, process the query result :)
    if ($ajax) then
        jquery:process(dict:transform($root[1]))
    (: else: just display the html page :)
    else
        let $content := request:get-data()
        return
            jquery:process($content)