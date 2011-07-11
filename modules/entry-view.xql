module namespace matumi="http://www.asia-europe.uni-heidelberg.de/xquery/matumi";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xql";
import module namespace dict="http://exist-db.org/xquery/dict" at "dict2html.xql";
import module namespace search="http://exist-db.org/xquery/search" at "search.xql";

declare function matumi:entry($node as node()*, $params as element(parameters)?, $model as item()*) {
    let $doc := request:get-parameter("doc", ())
    let $id := request:get-parameter("id", ())
    return
        if ($id) then
            let $entry := doc($doc)//tei:div[@type = "entry"][@subtype = $id]
            for $child in $node/node()
            return
                templates:process($child, request:get-attribute("$templates:prefixes"), $entry)
        else
            let $nodeId := request:get-parameter("node", ())
            let $target := util:node-by-id(doc($doc), $nodeId)
            let $entry := $target/ancestor-or-self::tei:div[@type = "entry"]
            for $child in $node/node()
            return
                templates:process($child,
                    request:get-attribute("$templates:prefixes"), $entry)
};

declare function matumi:encyclopedia-title($node as node()*, $params as element(parameters)?, $model as item()*) {
    $model/ancestor::tei:TEI/tei:teiHeader//tei:titleStmt/tei:title/text()
};

declare function matumi:format-entry($node as node()*, $params as element(parameters)?, $model as item()*) {
    dict:entry($model)
};

declare function matumi:tabs($node as node()*, $params as element(parameters)?, $model as item()*) {
    let $uri := replace(request:get-uri(), "^.*/([^/]+)$", "$1")
    let $log := util:log("DEBUG", ("$uri = ", $uri))
    return
        <ul class="tabs">{ for $child in $node/node() return matumi:process-tabs($child, $uri) }</ul>
};

declare function matumi:process-tabs($node as node(), $active as xs:string) {
    typeswitch ($node)
        case element(a) return
            <a>
            { 
                $node/@href,
                if ($node/@href eq $active) then
                    attribute class { "active" }
                else
                    (),
                $node/node()
            }
            </a>
        case element() return
            element { node-name($node) } {
                $node/@*, for $child in $node/node() return matumi:process-tabs($child, $active)
            }
        default return
            $node
};

declare function matumi:search($node as node()*, $params as element(parameters)?, $model as item()*) {
    let $results := search:search()
    return
        <div class="results">
        {
            for $child in $node/node()
            return
                templates:process($child, request:get-attribute("$templates:prefixes"), $results)
        }
        </div>
};

declare function matumi:results($node as node()*, $params as element(parameters)?, $model as item()*) {
    search:show-results($model)
};

declare function matumi:facets($node as node()*, $params as element(parameters)?, $model as item()*) {
    search:show-facets($model)
};

declare function matumi:query-form($node as node()*, $params as element(parameters)?, $model as item()*) {
    search:query-form()
};