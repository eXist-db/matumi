module namespace xutil="http://exist-db.org/xquery/xpath-util";

declare variable $xutil:COLLECTION := "/db/encyclopedia";

declare variable $xutil:ID := request:get-parameter("id", ());
declare variable $xutil:DOC := request:get-parameter("doc", ());
declare variable $xutil:NODEID := request:get-parameter("nodeId", ());
declare variable $xutil:TEXT := request:get-parameter("text", ());
declare variable $xutil:TITLE := request:get-parameter("title", ());

declare variable $xutil:MONTHS := ('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 
    'September', 'October', 'November', 'December');

declare function xutil:index-of-node( $nodes as node()* , $nodeToFind as node() )  as xs:integer* {
    for $seq in (1 to count($nodes))
    return $seq[$nodes[$seq] is $nodeToFind]
};
 
declare function xutil:path-to-node-with-pos( $node as node()?, $prefix as xs:string )  as xs:string {
    string-join(
        for $ancestor in $node/ancestor-or-self::*
        let $sibsOfSameName := $ancestor/../*[name() = name($ancestor)]
        return concat(
            $prefix, ":", local-name($ancestor),
            if (count($sibsOfSameName) <= 1) then ''
            else concat('[', xutil:index-of-node($sibsOfSameName,$ancestor), ']')
        )
    , '/')
 };
 
declare function xutil:get-location($source as element()) {
    let $start := xs:int(request:get-parameter("start", 0))
    let $end := xs:int(request:get-parameter("end", 0))
    let $child := xs:int(request:get-parameter("child", 0))
    let $node := $source/node()[$child + 1]
    (: let $updates := anno:update($node, $start, $end, $id) :)
    let $path := xutil:path-to-node-with-pos($source, "tei")
    (: let $replaced :=
        update replace $source with 
            element { node-name($source) } {
                $source/@*, $node/preceding-sibling::node(), $updates, $node/following-sibling::node()
            }:)
    return
        <exist:location doc="{document-uri(root($source))}" start="{$start + 1}" length="{$end - $start}">
            <exist:xpath>{$path}/node()[{$child + 1}]</exist:xpath>
            <exist:text>{substring($node, $start + 1, $end - $start)}</exist:text>
        </exist:location>
};

declare function xutil:xpath-for-node($node as node()?, $prefix as xs:string) {
    if ($node) then
        let $parent := $node/parent::*
        return
            typeswitch ($node)
                case element() return
                    if ($parent) then
                        let $siblings := util:eval(concat("$node/preceding-sibling::", node-name($node)))
                        return
                            string-join((
                                    xutil:xpath-for-node($parent, $prefix),
                                    concat($prefix, ":", local-name($node), "[", count($siblings) + 1, "]")
                                ),
                                "/"
                            )
                    else
                        concat($prefix, ":", local-name($node))
                default return
                    xutil:xpath-for-node($parent, $prefix)
    else
        ()
};

declare function xutil:format-dateTime($date as xs:dateTime?) {
    let $month := month-from-dateTime($date)
    let $dateStr := concat($xutil:MONTHS[$month], " ", day-from-dateTime($date), ", ", year-from-dateTime($date))
    return
        concat($dateStr, " ", hours-from-dateTime($date), ":", minutes-from-dateTime($date))
};