(:~
    Store annotations and markup.
:)
xquery version "1.0";

declare namespace anno="http://exist-db.org/xquery/annotate";
declare namespace atom="http://www.w3.org/2005/Atom";

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

import module namespace xdb="http://exist-db.org/xquery/xmldb";

import module namespace h2t="http://exist-db.org/xquery/html2tei" at "html2tei.xql";

import module namespace xutil="http://exist-db.org/xquery/xpath-util" at "path.xql";
    
declare variable $anno:NOTES_TMPL :=
    <TEI xmlns="http://www.tei-c.org/ns/1.0">
        <teiHeader>
            <fileDesc>
                <titleStmt>
                    <title></title>
                </titleStmt>
                <publicationStmt>
                    <date></date>
                </publicationStmt>
                <sourceDesc><p></p></sourceDesc>
            </fileDesc>
        </teiHeader>
        <text>
            <body>
            </body>
        </text>
    </TEI>;

(:~
    Retrieve or create the feed corresponding to the given resource.
:)
declare function anno:annotations($resource as xs:string, $source as element()) {
    let $ref := concat($resource, '#', util:node-id($source))
    let $location := xutil:get-location($source)
    let $feed := collection($config:app-root)//atom:feed[exist:location[@doc = document-uri($source)][exist:xpath = $location/exist:xpath]
        [@start = $location/@start][@length = $location/@length]]
    return
        if ($feed) then
            $feed
        else
            let $uuid := util:uuid()
            let $feedDoc :=
                <feed xmlns="http://www.w3.org/2005/Atom">
                    <id>urn:uuid:{$uuid}</id>
                    <title type="text">"{$xutil:TEXT}"</title> 
                    <link rel="related" href="{$ref}"/>
                    <updated>{current-dateTime()}</updated>
                    {$location}
                </feed>
            let $path := 
                xdb:store($config:app-root, concat($uuid, ".atom"), $feedDoc, "text/xml")
            return
                doc($path)//atom:feed
};

declare function anno:update($node as node(), $start as xs:int, $end as xs:int, $id as xs:string) {
    let $before := substring($node, 1, $start)
    let $after := substring($node, $end + 1)
    return
        ($before, <ref target="#{$id}" type="note">{substring($node, $start + 1, $end - $start)}</ref>, $after)
};

declare function anno:create-tag($id as xs:string, $content as xs:string?) {
    let $field := request:get-parameter("field", ())
    let $url := request:get-parameter("url", ())
    return
        if ($field = ('place', 'person', 'people')) then
            <name xml:id="{$id}" type="{$field}" key="{$url}">{$content}</name>
        else
            <term xml:id="{$id}" key="{$url}">{$content}</term>
};

declare function anno:insert-tag($node as node(), $start as xs:int, $end as xs:int) {
    let $before := substring($node, 1, $start)
    let $after := substring($node, $end + 1)
    let $id := anno:get-unique-id(root($node))
    return
        ($before, anno:create-tag($id, substring($node, $start + 1, $end - $start)), $after)
};

declare function anno:tag($source as element()) {
    let $start := xs:int(request:get-parameter("start", 0))
    let $end := xs:int(request:get-parameter("end", 0))
    let $child := xs:int(request:get-parameter("child", 0))
    let $node := $source/node()[$child + 1]
    let $updates := anno:insert-tag($node, $start, $end)
    return
        update replace $source with 
            element { node-name($source) } {
                $source/@*, $node/preceding-sibling::node(), $updates, $node/following-sibling::node()
            }
};

declare function anno:update-tag($doc as node(), $id as xs:string) {
    let $node := id($id, $doc)
    let $updated := anno:create-tag($id, $node/string())
    return
        update replace $node with $updated
};

declare function anno:get-unique-id($root as node()) {
    let $ids := 
        for $id in $root//@xml:id/string()
        where matches($id, "N\d+")
        return
            xs:integer(substring($id, 2))
    return
        concat("N", max(($ids, 0)) + 1)
};

declare function anno:parse-note() {
    let $note := concat("<div>", request:get-parameter("note", ()), "</div>")
    return
        if ($note) then
            util:parse-html($note)/*
        else
            error(xs:QName("anno:parser-error"), "no note text passed in")
};

(:~
    Add a new annotation/comment for the given resource.
:)
declare function anno:annotate($resource as xs:string, $source as element()) {
    let $note := anno:parse-note()
    let $content := $note//BODY/*
    let $annotations := anno:annotations($resource, $source)
    return (
        update insert
            <entry xmlns="http://www.w3.org/2005/Atom">
                <id>urn:uuid:{util:uuid()}</id>
                <title type="text">{$xutil:TITLE}</title>
                <updated>{current-dateTime()}</updated>
                <content>{$content}</content>
            </entry>
        into $annotations,
        $annotations
    )
};

declare function anno:update($id as xs:string) {
    let $note := anno:parse-note()
    (: let $tei := h2t:transform($note) :)
    let $content := $note//BODY/*
    let $feed := collection($config:app-root)/atom:feed[atom:id = $id]
    return (
        update insert
            <entry xmlns="http://www.w3.org/2005/Atom">
                <id>urn:uuid:{util:uuid()}</id>
                <title type="text">{$xutil:TITLE}</title>
                <updated>{current-dateTime()}</updated>
                <content>{$content}</content>
            </entry>
        into $feed,
        $feed
    )
};

let $action := request:get-parameter("action", "annotate")
let $id := request:get-parameter("id", ())
let $nodeId := request:get-parameter("nodeId", ())
let $resource := request:get-parameter("doc", ())
let $doc := doc($resource)
return
    if ($action eq 'annotate') then
        if ($id) then
            anno:update($id)
        else if ($nodeId) then
            let $source := util:node-by-id($doc, $nodeId)
            return anno:annotate($resource, $source) 
        else
            ()
    else
        if ($nodeId) then
            let $source := util:node-by-id($doc, $nodeId)
            return anno:tag($source)
        else if ($id) then
            anno:update-tag($doc, $id)
        else
            ()