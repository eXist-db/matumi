xquery version "3.0";

module namespace matumi="http://www.asia-europe.uni-heidelberg.de/xquery/matumi";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xql";
import module namespace dict="http://exist-db.org/xquery/dict" at "dict2html.xql";
import module namespace search="http://exist-db.org/xquery/search" at "search.xql";
import module namespace browse="http://exist-db.org/xquery/apps/matumi/browse" at "browse.xqm";
import module namespace browse-books="http://exist-db.org/xquery/apps/matumi/browse-books" at "browse_books.xqm";
import module namespace metadata="http://exist-db.org/xquery/apps/matumi/metadata" at "metadata.xqm";


declare function matumi:entry($node as node()*, $model as map(), $doc as xs:string?, $id as xs:string?) {
    if ($id) then
        let $entry := doc($doc)//tei:div[@type = "entry"][@subtype = $id]
        return
            map:entry("entry", $entry)
    else
        let $nodeId := request:get-parameter("node", ())
        let $target := util:node-by-id(doc($doc), $nodeId)
        let $entry := $target/ancestor-or-self::tei:div[@type = "entry"]
        return
            map:entry("entry", $entry)
};

declare function matumi:encyclopedia-title($node as node()*, $model as map()) {
    let $entry := $model("entry")
    let $title0 := $entry/ancestor::tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[@type = "main"]/text()
    let $title := 
        if( $title0 = ('', 'title', 'Title')) then 
            concat('[',  util:document-name($title0), ']') 
        else
            $title0
    return
        <a href="metadata.html?doc={  document-uri( root($entry)) }">{ $title }</a>
};

declare function matumi:encyclopedia-subjects($node as node()*, $model as map()) {
    let $subjects := $model("entry")/@subtype/string()
    for $subject in tokenize($subjects, "_")
    return
        <a href="browse.html?L1=subjects&amp;L2=entries&amp;L3=names&amp;L4=books&amp;subject={$subject}">{ $subject }</a>
   
};

declare function matumi:format-entry($node as node()*, $model as map()) {
    dict:entry($model("entry"))
};

declare function matumi:tabs($node as node()*, $model as map()) {
    let $uri := replace(request:get-uri(), "^.*/([^/]+)$", "$1")
    (:let $log := util:log("DEBUG", ("$uri = ", $uri)):)
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

declare function matumi:search($node as node()*, $map as map()) {
    let $results := search:search()
    return
        map:entry("results", $results)
};

declare function matumi:results($node as node()*, $model as map()) {
    search:show-results($model("results"))
};

declare function matumi:facets($node as node()*, $model as map(), $view as xs:string) {
    <div class="facet-list">
    { search:show-facets($model("results"), $view) }
    </div>
};

declare function matumi:query-form($node as node()*, $model as map()) {
    search:query-form()
};

declare function matumi:browse-boxes($node as node()*, $model as map()) {
    browse:level-boxes()
};

declare function matumi:browse-grid($node as node()*, $model as map()) {
     <div class="grid_16 browse-grid"> 
        { browse:page-grid( false() ) }
     </div>
};

declare
    %templates:default("L1", "entries")
function matumi:browse-select($node as node()*, $model as map(), $L1 as xs:string, $key as xs:string*) {
    let $L1 := if (exists($L1)) then $L1 else session:get-attribute("L1")
    let $key := if (exists($key)) then $key else session:get-attribute("key")
    return (
        session:set-attribute("L1", $L1),
        session:set-attribute("key", $key),
        switch ($L1)
            case "entries" return
                let $entries :=
                    collection($config:data-collection)/tei:TEI//tei:div[@type = "entry"]/tei:head/tei:term/string()
                for $entry in distinct-values($entries)
                order by $entry
                return
                    <option value="{$entry}">
                        { if ($key = $entry) then attribute selected { "selected" } else () }
                        { $entry }
                    </option>
            case "subjects" return
                let $types :=
                    collection($config:data-collection)/tei:TEI//tei:div[@type = "entry"]/@subtype
                for $type in distinct-values($types)
                order by $type
                return
                    <option value="{$type}">
                        { if ($key = $type) then attribute selected { "selected" } else () }
                        { $type }
                    </option>
            case "books" return
                for $tei in collection($config:data-collection)/tei:TEI
                let $title := matumi:get-title($tei)
                let $id := $tei/@xml:id/string()
                return
                    <option value="{$id}">
                        { if ($key = $id) then attribute selected { "selected" } else () }
                        { $title }
                    </option>
            case "names" return
                let $types :=
                    collection($config:data-collection)/tei:TEI//tei:div[@type = "entry"][@subtype]//tei:name/@key
                for $type in distinct-values($types)
                order by $type
                return
                    <option value="{$type}">
                        { if ($key = $type) then attribute selected { "selected" } else () }
                        { matumi:extract-key($type) }
                    </option>
            default return
                ()
    )
};

declare function matumi:metadata-combo($node as node()*, $model as map()) {
   metadata:all( $node, $params, $model) 
};

declare
    %templates:wrap
function matumi:browse($node as node(), $model as map(*), $L1 as xs:string, $key as xs:string*) {
    let $data :=
        if (exists($key)) then
            switch ($L1)
                case "entries" return
                    collection($config:data-collection)/tei:TEI//tei:div[tei:head/tei:term = $key][@type = "entry"]
                case "subjects" return
                    collection($config:data-collection)/tei:TEI//tei:div[@subtype = $key][@type = "entry"]
                case "books" return
                    collection($config:data-collection)/tei:TEI[@xml:id = $key]//tei:div[@type = "entry"][@subtype]
                case "names" return
                    collection($config:data-collection)/tei:TEI//tei:div[.//tei:name/@key = $key][@type = "entry"][@subtype]
                default return
                    ()
        else
            session:get-attribute("matumi.browse")
    return (
        session:set-attribute("matumi.browse", $data),
        map { "browse" := $data }
    )
};

declare function matumi:browse-summary($node as node(), $model as map(*)) {
    for $div in $model("browse")
    let $root := $div/ancestor::tei:TEI
    return
        <tr>
            <td>{ matumi:get-title($root)/text() }</td>
            <td>
                <a class="entry-derect-link" href="entry.html?doc={document-uri(root($div))}&amp;node={util:node-id($div)}">
                { $div/tei:head/string() }
                </a>
            </td>
            <td>
            {
                if( exists( $div/@subtype )) then 
                    matumi:capitalize-first($div/@subtype )
   			    else '-'
            }
            </td>
            <td class="cat-container expanded">
                <span class="cat-toggle expanded"></span>
                {
                    matumi:get-categories($div)
                }
            </td>
        </tr>
};

declare %private function matumi:get-categories($div as element(tei:div)) {
    for $name in $div//tei:name
    group $name as $byType by $name/@type as $type
    return (
        <span class="cat-name">{$type/string()}:</span>,
        <span class="values">
        {
            let $names :=
                for $name in $byType
                group $name as $distinct by $name/@key as $key
                return (
                    ", ",
                    <a href="entry.html?doc={document-uri(root($div))}&amp;node={util:node-id($div)}&amp;key={$key}">
                    { matumi:extract-key($key) }
                    </a>
                )
            return
                subsequence($names, 2)
        }
        </span>
    )
};

declare %private function matumi:extract-key($key as xs:string) {
    translate(replace($key, "^.*/([^\[]+)$", "$1"), "_", " ")
};

declare %private function matumi:get-title($tei as element(tei:TEI)) {
    let $title := $tei/tei:teiHeader/tei:fileDesc/tei:titleStmt
    return
        if (exists($title/tei:title[@type='main'])) then
            $title/tei:title[@type="main"]/text()
        else if( string($title[empty(@type)][1]) = 'Title' or empty($title/tei:title) or fn:string-join($title/tei:title,'') = '' ) then 
            concat('[',  util:document-name($tei), ']') 
        else $title/tei:title/text()
};

declare %private function matumi:capitalize-first($string as xs:string) {
    upper-case(substring($string, 1, 1)) || substring($string, 2)
};