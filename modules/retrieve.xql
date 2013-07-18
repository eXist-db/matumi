xquery version "1.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option exist:serialize "media-type=text/html";

import module namespace tei2html="http://exist-db.org/xquery/tei2html" at "tei2html.xql";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

let $id := request:get-parameter("id", ())
let $resource := request:get-parameter("doc", ())
let $doc := doc(concat($config:data-collection, "/", $resource, ".notes"))
(:let $doc := doc(concat($config:app-root, "/", $resource, ".notes")):)
return
    tei2html:tei-to-html($doc//tei:note[@xml:id = $id])