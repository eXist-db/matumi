xquery version "1.0";

declare namespace anno="http://exist-db.org/xquery/annotate";
declare namespace atom="http://www.w3.org/2005/Atom";

import module namespace jquery="http://exist-db.org/xquery/jquery" at "resource:org/exist/xquery/lib/jquery.xql";
import module namespace xutil="http://exist-db.org/xquery/xpath-util" at "path.xql";

declare option exist:serialize "method=xhtml media-type=text/html";

declare variable $anno:COLLECTION := "/db/Encyclopedias";

declare variable $anno:ID := request:get-parameter("id", ());
declare variable $anno:DOC := request:get-parameter("doc", ());
declare variable $anno:NODEID := request:get-parameter("nodeId", ());
declare variable $anno:DATA := request:get-attribute("data");

declare function anno:entries($feed as element()?) {
    for $entry in $feed/atom:entry
    return
        <div class="atom-entry">
            <h2>{$entry/atom:title/text()}</h2>
            <div class="date">{xutil:format-dateTime(xs:dateTime($entry/atom:updated))}</div>
            { $entry/atom:content/* }
        </div>
};

declare function anno:feed($data as element()?) {
    let $feed := if ($data) then $data else collection($anno:COLLECTION)/atom:feed[atom:id = $anno:ID]
    return
        <div class="feed">
            <p class="feedref">{$feed/exist:location/exist:text/string()}</p>
            {anno:entries($feed)}
        </div>
};

declare function anno:html() {
    <div id="annotations">
        { anno:feed($anno:DATA) }
        
        <p class="comment-btns"><button class="toggle-editor">Add Comment</button><button class="close-annotations">Close</button></p>
        <div class="editor">
            <form action="#" class="editor-form" name="editor-form" method="post">
                <table>
                    <tr>
                        <td class="label">Title (optional):</td>
                        <td><input type="text" size="60" name="title"/></td>
                    </tr>
                    <tr>
                        <td colspan="2">
                            <textarea name="note" class="editor-area"></textarea>
                        </td>
                    </tr>
                    <tr>
                        <td colspan="2"><button type="submit">Send</button></td>
                    </tr>
                </table>
                <input type="hidden" name="action" value="annotate"/>
                <input type="hidden" name="doc" value="{request:get-parameter('doc', ())}"/>
                <input type="hidden" name="nodeId" value="{request:get-parameter('nodeId', ())}"/>
                <input type="hidden" name="start" value="{request:get-parameter('start', ())}"/>
                <input type="hidden" name="end" value="{request:get-parameter('end', ())}"/>
                <input type="hidden" name="child" value="{request:get-parameter('child', ())}"/>
                <input type="hidden" name="id" value="{if ($anno:DATA) then $anno:DATA/atom:id else $anno:ID}"/>
                <input type="hidden" name="text" value="{$xutil:TEXT}"/>
            </form>
        </div>
    </div>
};

declare function anno:page() {
    <html xmlns:jquery="http://exist-db.org/xquery/jquery">
        <head>
            <jquery:header base="../scripts/jquery" cssbase="../scripts/jquery/css"/>
            <script type="text/javascript" src="resources/scripts/wymeditor/jquery.wymeditor.min.js"></script> 
            <script type="text/javascript" src="resources/scripts/notes.js"></script>
            <link rel="stylesheet" type="text/css" href="../scripts/jquery/css/smoothness/jquery.ui.all.css"/>
            <link type="text/css" href="style.css" rel="stylesheet"></link>
        </head>
        <body>
            { anno:html() }
        </body>
    </html>
};

let $mode := request:get-parameter("mode", "inline")
let $action := request:get-parameter("action", ())
return
    if ($action eq "annotate") then
        anno:feed($anno:DATA)
    else if ($mode eq 'inline') then
        anno:html()
    else
        jquery:process(anno:page())