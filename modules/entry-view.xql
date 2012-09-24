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
    let $data := if ($view = "entry") then $model("entry") else $model("results")
    return
        <div class="facet-list">
        { search:show-facets($data, $view) }
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
    %templates:default("L1", "subjects")
    %templates:default("L2", "names")
function matumi:browse-select($node as node()*, $model as map(), $level as xs:int, $L1 as xs:string, $key1 as xs:string*, $L2 as xs:string, $key2 as xs:string*) {
    let $L1 := matumi:get-set-session($L1, "L1")
    let $key1 := matumi:get-set-session($key1, "key1")
    let $L2 := matumi:get-set-session($L2, "L2")
    let $key2 := matumi:get-set-session($key2, "key2")
    return
        matumi:select($level, $L1, $key1, $L2, $key2)
};

declare function matumi:get-set-session($param as xs:string*, $name as xs:string) {
    let $value :=
        if (exists($param)) then $param else session:get-attribute($name)
    let $value := if ($value = "") then () else $value
    return (
        session:set-attribute($name, $value),
        $value
    )
};

declare %private function matumi:select($level as xs:int, $L1 as xs:string, $key1 as xs:string*, $L2 as xs:string, $key2 as xs:string*) {
    let $L := if ($level = 1) then $L1 else $L2
    let $key := if ($level = 1) then $key1 else $key2
    let $divs := 
        if ($level = 1) then
            collection($config:data-collection)/tei:TEI//tei:div[@type = "entry"]
        else
            matumi:select-entries($L1, $key1)
    return (
        switch ($L)
            case "entries" return
                let $entries :=
                    $divs/tei:head/tei:term/string()
                for $entry in distinct-values($entries)
                order by $entry
                return
                    <option value="{$entry}">
                        { if ($key = $entry) then attribute selected { "selected" } else () }
                        { $entry }
                    </option>
            case "subjects" return
                let $types := $divs/@subtype
                for $type in distinct-values($types)
                order by $type
                return
                    <option value="{$type}">
                        { if ($key = $type) then attribute selected { "selected" } else () }
                        { matumi:capitalize-first(translate($type, "_", " ")) }
                    </option>
            case "books" return
                for $tei in $divs/ancestor::tei:TEI
                let $title := matumi:get-title($tei)
                let $id := $tei/@xml:id/string()
                return
                    <option value="{$id}">
                        { if ($key = $id) then attribute selected { "selected" } else () }
                        { $title }
                    </option>
            case "names" return
                let $types :=
                    $divs[@subtype]//tei:name/@key
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

declare
    %templates:wrap
function matumi:metadata-select($node as node()*, $model as map(), $doc as xs:string?) {
   let $books := collection($config:data-collection)/tei:TEI
   for $book in $books
   let $title := matumi:get-title($book)
   let $uri := document-uri(root($book))
   return
        <option value="{$uri}">
        {
           if ($uri = $doc) then
               attribute selected { "selected" }
            else
                ()
        }
        {$title}
        </option>
};

declare function matumi:metadata-display($node as node(), $model as map(*), $doc as xs:string?) {
    let $uri-annotation := concat(substring-before($doc, '.xml'), '-annotations.xml')
    let $doc-annotation := if (doc-available($uri-annotation)) then doc($uri-annotation)/tei:TEI else ()
    let $annotation-body := $doc-annotation//tei:body
    
    let $doc := doc($doc)/tei:TEI
    let $fileDesc := $doc/tei:teiHeader//tei:fileDesc
    let $sourceDesc := $fileDesc/tei:sourceDesc
    let $biblFull := $sourceDesc/tei:biblFull
    let $msDesc := $sourceDesc/tei:msDesc
    let $profileDesc := $doc/tei:teiHeader//tei:profileDesc
    return
        <div> 
            <h2>Source Description</h2>      
            <table class="metadata" cellspacing="3" cellpadding="3"  width="100%">
             <tbody>{
                metadata:process('Title', $biblFull/tei:titleStmt/tei:title ),
                metadata:process('Author', $biblFull/tei:titleStmt/tei:author ),
                metadata:process('Editor', $biblFull/tei:titleStmt/tei:editor ),
                metadata:process('Publisher', $biblFull/tei:publicationStmt/tei:publisher ),
                metadata:process('Date', $biblFull/tei:editionStmt/tei:date),
                metadata:process('Edition', $biblFull/tei:editionStmt/tei:edition ),
                metadata:process('Other editions', $biblFull/tei:notesStmt ),
                metadata:process('Physical Description', $msDesc/tei:physDesc),
                metadata:process('Content', $msDesc/tei:msPart/tei:msContents ),
                metadata:process('History of the manuscript', $msDesc/tei:msPart/tei:history )    
             }</tbody>
            </table>
            
            <h2>Profile Description</h2>      
            <table class="metadata" cellspacing="3" cellpadding="3"  width="100%">
             <tbody>{
                 metadata:process('Language', $profileDesc/tei:langUsage ),
                 metadata:process('Publication circumstances', $profileDesc/tei:settingDesc ),
                 metadata:process('Background of authors and editors', $profileDesc/tei:particDesc/tei:listPerson ),
                 metadata:process('Genre and style', $profileDesc/tei:textDesc ) 
             }</tbody>
            </table>
            
            <h2>Analysis</h2>      
            <table class="metadata" cellspacing="3" cellpadding="3"  width="100%">
             <tbody>{
                 metadata:process('Translations of Prefaces', $annotation-body/tei:div/@type[. = 'preface-translation']),
                 metadata:process('Analysis of Prefaces', $annotation-body/tei:div/@type[. = 'preface-analysis']),
                 metadata:process('Analysis of advertisements for this book', $annotation-body/tei:div/@type[. = 'advertisement-analysis']),
                 metadata:process('Advertisements in this books', $annotation-body/tei:div/@type[. = 'advertisement-for-this-book']),
                 metadata:process('Analysis of readership', $annotation-body/tei:div/@type[. = 'readership']),
                 metadata:process('Hidden grammars - underlying world view or intention', $annotation-body/tei:div/@type[. = 'HiddenGrammars']),
                 metadata:process('Secondary literature  on this encyclopedia', $annotation-body/tei:div/@type[. = 'secondary-literature']),
                 metadata:process('Open Questions', $annotation-body/tei:div/@type[. = 'open-questions']),
                 ()
             }</tbody>
            </table>
        </div>
};

declare
    %templates:wrap
function matumi:browse($node as node(), $model as map(*), $L1 as xs:string, $key1 as xs:string*, $L2 as xs:string, $key2 as xs:string*) {
    let $L1 := matumi:get-set-session($L1, "L1")
    let $key1 := matumi:get-set-session($key1, "key1")
    let $L2 := matumi:get-set-session($L2, "L2")
    let $key2 := matumi:get-set-session($key2, "key2")
    let $data :=
        if (exists($key1) and exists($key2)) then
            matumi:select-entries($L1, $key1) intersect matumi:select-entries($L2, $key2)
        else if (exists($key1)) then
            matumi:select-entries($L1, $key1)
        else
            session:get-attribute("matumi.browse")
    return (
        session:set-attribute("matumi.browse", $data),
        map { "browse" := $data }
    )
};

declare function matumi:select-entries($level as xs:string, $key as xs:string) {
    switch ($level)
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
};

declare function matumi:browse-summary($node as node(), $model as map(*)) {
    for $div in $model("browse")
    let $tei := $div/ancestor::tei:TEI
    return
        <tr>
            <td>
            { 
                matumi:get-title($tei)
            }
            </td>
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
                <ul>
                {
                    matumi:get-categories($div)
                }
                </ul>
            </td>
        </tr>
};

declare %private function matumi:get-categories($div as element(tei:div)) {
    for $name in $div//tei:name
    group $name as $byType by $name/@type as $type
    return
        let $names :=
            for $name in $byType[@key]
            group $name as $distinct by $name/@key as $key
            return (
                ", ",
                <a href="entry.html?doc={document-uri(root($div))}&amp;node={util:node-id($div)}&amp;key={$key}">
                { matumi:extract-key($key) }
                </a>
            )
        return
            if (exists($names)) then
                <li>
                    <span class="cat-toggle expanded"></span>
                    <span class="cat-name">{$type/string()}:</span>
                    <span class="values">
                    {
                        subsequence($names, 2)
                    }
                    </span>
                </li>
            else
                ()
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

declare function matumi:dump-session() {
    for $attr in session:get-attribute-names()
    return
        util:log("DEBUG", $attr || " = " || (if ($attr) then session:get-attribute($attr) else ()))
};