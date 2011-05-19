module namespace h2t="http://exist-db.org/xquery/html2tei";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function h2t:apply($node as node()?) {
    for $child in $node/node() return h2t:transform($child)
};

declare function h2t:transform($node as node()) {
    typeswitch ($node)
        case element(p) return
            <tei:p>{h2t:apply($node)}</tei:p>
        case element(em) return
            <tei:hi rend="italics">{h2t:apply($node)}</tei:hi>
        case element(strong) return
            <tei:hi rend="bold">{h2t:apply($node)}</tei:hi> 
        case element() return
            h2t:apply($node)
        case text() return
            $node
        default return
            ()
};

declare function h2t:to-html($node as node()?) {
    for $child in $node/node() return h2t:tei-to-html($child)
};

declare function h2t:tei-to-html($node as node()) {
    typeswitch ($node)
        case element(tei:p) return
            <p>{h2t:to-html($node)}</p>
        case element(tei:hi) return
            if ($node/@rend = 'bold') then
                <strong>{h2t:to-html($node)}</strong>
            else
                <em>{h2t:to-html($node)}</em>
        case element(tei:gloss) return
            <span class="gloss" title="{$node/@target}">{h2t:to-html($node)}</span>
        case element(tei:term) return
            <a class="term" href="{$node/@key}">{h2t:to-html($node)}</a>
        case element(tei:name) return
            <a class="{$node/@type}" href="{$node/@key}">{h2t:to-html($node)}</a>
        case element() return
            h2t:to-html($node)
        case text() return
            $node
        default return
            ()
};