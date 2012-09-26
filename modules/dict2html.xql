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
    (:let $log := util:log("DEBUG", ("Text: ", $node)):)
    for $location in collection($config:app-root)//atom:feed/exist:location[@doc = $document-uri]
    let $target := util:eval(concat("root($node)/", $location/exist:xpath))
    (:let $log := util:log("DEBUG", ("Target: ", $target)):)
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
                if ($node/@type = 'advertisement' or $node/@subtype = 'advertisement')  then
                    <div class="contentdesc">
                        <div class="contentdesctitle">[Advertisement]</div>
                        {dict:process-children($documentURI, $node, $comments)}
                    </div>
                 else
                    dict:process-children($documentURI, $node, $comments)
                    
            case element(tei:head) return
                let $level := count($node/ancestor::tei:div)
                return (
                    (: <a href="edit.xql?doc={document-uri(root($node))}&amp;nodeId={util:node-id($node)}" class="edit" target="_new">Edit</a>, :)
                    element { concat("h", $level) } {
                        dict:process-children($documentURI, $node, $comments)
                    }
                )
    
            case element(tei:lb) return
                <br/>
            case element(tei:fw) return
                <p class="rh">{$node/text()}</p>
            case element(tei:unclear) return
                (
                
                <span class="unclear" title="unclear. reason: {$node/@reason}">{dict:process-children($documentURI, $node, $comments)}<span class="unclear-fragezeichen">?</span></span>
            )
            case element(tei:gap) return 
                <span class="gapinfo" title="reason: {$node/@reason}">[gap:{fn:string($node/@extent)}{fn:string($node/@unit)}]</span>
                
            case element(tei:figure) return (
                <img class="figure" src="{fn:string($node/@facs)}"/>,
                <div class="figure"><span class="addition">[Figure above:]</span> {dict:process-children($documentURI, $node, $comments)}</div>
            )
            case element(tei:figDesc) return 
                <span class="addition">{dict:process-children($documentURI, $node, $comments)}</span> 
            case element(tei:anchor) return (
                <a name="{fn:string($node/@xml:id)}"/>
            )
            case element(tei:note) return
                if ($node/@author) then
                    <span class="note">Note by {fn:string($node/@author)}: {fn:string($node)}</span>
                else if ($node/@resp) then
                    <span class="noteresp">Note by {fn:string($node/@resp)}: {fn:string($node)}</span>
                else
                    <span class="note">Note: {fn:string($node)}</span>
            case element(tei:add) return        
                if ($node/@resp) then
                    <span class="addition" title="Addition by {fn:string($node/@resp)}">{fn:string($node)}</span>
                else
                    <span class="addition">{fn:string($node)}</span>
            
            
            
            case element(tei:choice) return
                <span class="choice">
                    {dict:process-children($documentURI, $node, $comments)}
                </span>
            case element(tei:reg) return
                <span class="reg" title="regularized form">
                    ({dict:process-children($documentURI, $node, $comments)})
                </span>
            case element(tei:orig) return
                <span class="orig">
                    {dict:process-children($documentURI, $node, $comments)}
                </span>
            case element(tei:seg) return
                if ($node/@type eq "alternative") then
                <span class="alternative">
                    /{dict:process-children($documentURI, $node, $comments)}
                </span>
                else dict:process-children($documentURI, $node, $comments)
                
            case element(tei:table) return
                <table class="teitable">           
                    {dict:process-children($documentURI, $node, $comments)}
                </table>
            case element(tei:row) return
                <tr>           
                    {dict:process-children($documentURI, $node, $comments)}
                </tr>
             case element(tei:cell) return
                <td>           
                    {dict:process-children($documentURI, $node, $comments)}
                </td>
            case element(tei:pb) return 
               <span id="wrapper">
                 <div class="pb">{fn:string($node/@n)} 
                 <div class="pageview" id="pageview_{fn:string($node/@n)}">
                        <div class="osize">
                            Orig.Page:<br/>
                            <a class="osize" href="{fn:string($node/@facs)}" target="_blank"><b>++</b><br/> 100% </a> 
                            <div class="buttons">
                                <a class="scale"><b>+</b> Bigger</a>
                                <a class="close"><b>-</b> Smaller</a>
                        </div></div>
                        <img class="facsimile" src="{fn:string($node/@facs)}" id="image_{fn:string($node/@n)}"/>                                        
                  </div>
                  </div>
                  <div id="buffer"></div>
               </span>
            case element(tei:ruby) return 
                <ruby>{dict:process-children($documentURI, $node, $comments)}</ruby>
            case element(tei:rbase) return
                <rb>{dict:process-children($documentURI, $node, $comments)}</rb>
            case element(tei:rtext) return
                <rt>{dict:process-children($documentURI, $node, $comments)}</rt>
            case element(tei:charDecl) return ()
            case element(tei:g) return
              if ($node/@type = 'V') then
                <span class="character-variant" title="character variant">{$node/text()}</span>
              else if ($node/@type = 'R') then
                <span class="character-oldradical" title="character with old radical">{$node/text()}</span>
              else if ($node/@type = 'R') then
                <span class="character-oldradical character-variant" title="character variant with old radical">{$node/text()}</span>
              else
                 <b>
                    {   
                        let $id := replace($node/@ref, '#', '')             
                        let $glyph := doc($documentURI)//tei:charDecl/tei:glyph[@xml:id = $id]   
                        return <img class="non-unicode-char" src="{fn:string($glyph/tei:graphic/@url)}" alt="(non-unicode-char)" title="(non-unicode-char)"/>                
                    }
                </b> 
            case element(tei:list) return
                if ($node/@type = 'toclist') then
                    <div class="contentdesc">
                        <div class="contentdesctitle">[Table of Contents]</div>
                        <ul class="toclist">
                        { dict:process-children($documentURI, $node, $comments) }
                        </ul>
                    </div>
                else
                    <ul>
                    { dict:process-children($documentURI, $node, $comments) }
                    </ul>
            case element(tei:item) return
                if ($node/@rend = '1') then
                    <li class="level1">{ dict:process-children($documentURI, $node, $comments) }</li>
                else if ($node/@rend = '2') then
                    <li class="level2">{ dict:process-children($documentURI, $node, $comments) }</li>
                else if ($node/@rend = '3') then
                    <li class="level3">{ dict:process-children($documentURI, $node, $comments) }</li>
                else if ($node/@rend = '4') then
                    <li class="level4">{ dict:process-children($documentURI, $node, $comments) }</li>
                else if ($node/@rend = '5') then
                    <li class="level5">{ dict:process-children($documentURI, $node, $comments) }</li>
                else if ($node/@rend = '6') then
                    <li class="level6">{ dict:process-children($documentURI, $node, $comments) }</li>
                else
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
                else if ($node/@rend = 'listpagenumber') then
                    <div style="float:right;" id="{$node/@exist:id}">{dict:process-children($documentURI, $node, $comments)}</div>
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
                        title="External Link">{fn:string($node/@type)}{dict:process-children($documentURI, $node, $comments)}</a>
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
    (:let $log := util:log("DEBUG", ("Comments: ", $comments)):)
    let $entries := $expanded//tei:entry
    return
        if ($entries) then
            for $entry in $entries return dict:process-entries($documentURI, $entry, $comments)
        else
            for $entry in $expanded return dict:process($documentURI, $entry, $comments)
};

declare function dict:entry($entry as node()?) {
    let $documentURI := document-uri(root($entry))
    let $expanded := util:expand($entry, "add-exist-id=all")
    let $comments := dict:comments($expanded, $documentURI)
    return dict:process($documentURI, $expanded, $comments)       
};

declare function dict:transform($root as node()?) {
    <div>
        {dict:entries($root)}
    </div>
};
