xquery version "1.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option exist:serialize "media-type=text/html";

import module namespace h2t="http://exist-db.org/xquery/html2tei" at "html2tei.xql";

declare variable $local:COLLECTION := "/db/encyclopedia";

let $id := request:get-parameter("id", ())
let $resource := request:get-parameter("doc", ())
let $doc := doc(concat($local:COLLECTION, "/", $resource, ".notes"))
return
    h2t:tei-to-html($doc//tei:note[@xml:id = $id])