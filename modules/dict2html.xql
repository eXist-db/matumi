(:~
    Handles the transformation of TEI markup to HTML.
:)
module namespace dict="http://exist-db.org/xquery/dict";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace atom="http://www.w3.org/2005/Atom";

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

declare function dict:comments($root as node()?, $docURI as xs:string) {
    let $locations := collection($config:app-root)//atom:feed/exist:location[@doc = $docURI]
    for $location in $locations
    let $target := util:eval(concat("root($root)/", $location/exist:xpath))
    return
        $target
};

declare function dict:find-comment($document-uri as xs:string, $node as node()) {
    let $log := util:log("DEBUG", ("Text: ", $node))
    for $location in collection($config:app-root)//atom:feed/exist:location[@doc = $document-uri]
    let $target := util:eval(concat("root($node)/", $location/exist:xpath))
    let $log := util:log("DEBUG", ("Target: ", $target))
    return
        if ($node is $target) then
            $location
        else
            ()
};

declare function dict:capitalize-first($str as xs:string) as xs:string {
    concat(upper-case(substring($str,1,1)), substring($str,2))
 };
 
declare function dict:name-facet($root as element()?, $type as xs:string) {
    <div class="facet">
        <h3>{dict:capitalize-first($type)}</h3>
        <ul>
        {
            let $names :=
                distinct-values(
                    for $name in $root//tei:name[@type = $type]
                    return
                        $name/@key
                )
            for $name in $names order by $name
            return
                <li>
                    {translate(replace($name, "^.*/([^/]+)", "$1"), "_", " ")}
                    <span class="facet-links">
                        <a href="{$name}" target="_new">
                            DBpedia
                        </a>
                        |
                        <a class="key-search" 
                            href="{$name}" target="_new">
                            Search
                        </a>
                    </span>
                </li>
        }
        </ul>
    </div>
};

declare function dict:facets($root as element()?) {
    <div id="facets">
    {
        for $facet in distinct-values($root//tei:name/@type)
        order by $facet
        return dict:name-facet($root, $facet)
    }
    </div>
};

declare function dict:process-children($documentURI as xs:string, $node as element(), $comments as node()*) {
    for $child in $node/node() return dict:process($documentURI, $child, $comments)
};

declare function dict:edit-link($node as element()) {
    if ($node/@xml:id) then
        <a class="edit-link" href="#{$node/@xml:id}">edit</a>
    else
        ()
};

declare function dict:process-comment($text as xs:string, $locations as element()*, $offset as xs:int) {
    if (empty($locations) and $offset lt string-length($text)) then
        substring($text, $offset)
    else
        let $location := subsequence($locations, 1, 1)
        let $before := substring($text, $offset, ($location/@start + $location/@length) - $offset)
        return 
            if (empty($location/@start)) then 
                substring($text, $offset)
                (: {substring($text, $location/@start, $location/@length)} :)
            else
            (
                $before,
                <a href="annotate.xql?id={$location/../atom:id}&amp;mode=inline" target="_new"
                    class="annotation" title="{$location/exist:text}">
                    <img src="theme/images/comment_add.png" height="16"/>
                </a>,
                dict:process-comment($text, subsequence($locations, 2), $location/@start + $location/@length)
            )
};

declare function dict:process($documentURI as xs:string, $nodes as node()*, $comments as node()*) {
    for $node in $nodes
    return
        typeswitch ($node)
            case element(tei:teiHeader) return
                ()
            case element(tei:div) return
                dict:process-children($documentURI, $node, $comments)
            case element(tei:head) return
                let $level := count($node/ancestor::tei:div)
                return (
                    (: <a href="edit.xql?doc={document-uri(root($node))}&amp;nodeId={util:node-id($node)}" class="edit" target="_new">Edit</a>, :)
                    element { concat("h", $level) } {
                        dict:process-children($documentURI, $node, $comments)
                    }
                )
            case element(tei:list) return
                <ul>
                { dict:process-children($documentURI, $node, $comments) }
                </ul>
            case element(tei:item) return
                <li>{ dict:process-children($documentURI, $node, $comments) }</li>
            case element(tei:form) return (
                <span class="orth">{dict:process($documentURI, $node/tei:orth, $comments)}</span>,
                <span class="gramGrp">{dict:process($documentURI, $node/tei:gramGrp, $comments)}</span>
            )
            case element(tei:sense) return
                <p id="{$node/@exist:id}">{dict:process-children($documentURI, $node, $comments)}</p>
            case element(tei:def) return
                <span id="{$node/@exist:id}" class="def">{dict:process-children($documentURI, $node, $comments)}</span>
            case element(tei:cit) return
                <span id="{$node/@exist:id}" class="cit">{dict:process-children($documentURI, $node, $comments)}</span>
            case element(tei:quote) return
                <span id="{$node/@exist:id}" class="quote {$node/@rend}">{dict:process-children($documentURI, $node, $comments)}</span>
            case element(tei:emph) return
                if ($node/@rend = 'small caps') then
                    <span id="{$node/@exist:id}" class="smallcaps">{dict:process-children($documentURI, $node, $comments)}</span>
                else
                    <span id="{$node/@exist:id}" class="italic">{dict:process-children($documentURI, $node, $comments)}</span>
            case element(tei:hi) return
                if ($node/@rend = 'bold') then
                    <b id="{$node/@exist:id}">{dict:process-children($documentURI, $node, $comments)}</b>
                else
                    <span id="{$node/@exist:id}" class="italic">{dict:process-children($documentURI, $node, $comments)}</span>
            case element(tei:name) return (
                <a class="{$node/@type} name" id="{$node/@exist:id}" 
                    href="{$node/@key}" target="_new" rel="{replace($node/@key, "^.*/([^/]+)", "$1")}">
                    {dict:process-children($documentURI, $node, $comments)}
                </a>
            ) case element(tei:term) return (
                if ($node/@key) then
                    <a class="term" id="{$node/@exist:id}" href="{$node/@key}" target="_new">{dict:process-children($documentURI, $node, $comments)}</a>
                else
                    <b class="term" id="{$node/@exist:id}">{dict:process-children($documentURI, $node, $comments)}</b>
            )
            case element(tei:ref) return
                if ($node/@target) then
                    <a href="{$node/@target}" id="{$node/@exist:id}" target="_new" 
                        title="External Link">{dict:process-children($documentURI, $node, $comments)}</a>
                else
                    dict:process-children($documentURI, $node, $comments)
            case element(exist:match) return
                <span class="hi">{dict:process-children($documentURI, $node, $comments)}</span>
            case element(tei:p) return
                <div>
                    <!--a href="edit.xql?doc={document-uri(root($node))}&amp;nodeId={$node/@exist:id}" class="edit" target="_new">Edit</a-->
                    <p id="{$node/@exist:id}" class="block">{dict:process-children($documentURI, $node, $comments)}</p>
                </div>
            case element() return
                <span id="{$node/@exist:id}">{dict:process-children($documentURI, $node, $comments)}</span>
            case text() return
                if (exists(index-of($comments, $node))) then
                    let $locations :=
                        for $location in dict:find-comment($documentURI, $node) order by xs:int($location/@start) return $location
                    let $processed :=
                        dict:process-comment($node/string(), $locations, 1)
                    return
                        $processed
                else
                    $node
            default return
                $node
};

declare function dict:process-entries($documentURI as xs:string, $entry as element(tei:entry), $comments as node()*) {
    <p id="{$entry/@exist:id}">
        { dict:process($documentURI, $entry/tei:form, $comments) }
        { dict:process($documentURI, $entry/tei:sense[1]/*, $comments) }
    </p>,
    dict:process($documentURI, $entry/tei:sense[position() > 1], $comments),
    dict:process($documentURI, $entry/tei:note, $comments)
};

declare function dict:process-div($div as element(tei:div), $comments as node()*) {
    <p id="{$div/@exist:id}">
        <span class="orth">{dict:process($documentURI, $div/tei:head, $comments)}</span>
        { dict:process($documentURI, $div//tei:p[1], $comments) }
    </p>,
    dict:process($documentURI, $div//tei:p[position() > 1], $comments)
};

declare function dict:entries($root as node()?) {
    let $documentURI := document-uri(root($root))
    let $expanded := util:expand($root, "add-exist-id=all")
    let $comments := dict:comments($expanded, $documentURI)
    let $log := util:log("DEBUG", ("Comments: ", $comments))
    let $entries := $expanded//tei:entry
    return
        if ($entries) then
            for $entry in $entries return dict:process-entries($documentURI, $entry, $comments)
        else
            for $entry in $expanded return dict:process($documentURI, $entry, $comments)
};

declare function dict:transform($root as node()?) {
    <div>
        {dict:entries($root)}
    </div>
};