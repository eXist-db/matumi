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

declare variable $anno:COLLECTION := "/db/encyclopedia";

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
return
    jquery:process(dict:transform($root[1]))
    (: jquery:process-templates(dict:transform(util:expand($root, "add-exist-id=all indent=no"))) :)