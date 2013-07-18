xquery version "1.0";

declare namespace edit="http://exist-db.org/xquery/encyclopedia/edit";

import module namespace jquery="http://exist-db.org/xquery/jquery" at "resource:org/exist/xquery/lib/jquery.xql";
import module namespace xutil="http://exist-db.org/xquery/xpath-util" at "path.xql";
import module namespace tei2html="http://exist-db.org/xquery/tei2html" at "tei2html.xql";

declare option exist:serialize "method=xhtml media-type=text/html";

declare variable $edit:COLLECTION := "/db/resources/commons/encyclopedias";

declare variable $edit:DOC := request:get-parameter("doc", ());
declare variable $edit:NODEID := request:get-parameter("nodeId", ());

declare function edit:retrieve-block() {
    util:node-by-id(doc($edit:DOC), $edit:NODEID)
};

declare function edit:block-to-html() {
    tei2html:tei-to-html(edit:retrieve-block())
};

declare function edit:html() {
    <html xmlns:jquery="http://exist-db.org/xquery/jquery">
        <head>
            <jquery:header base="../scripts/jquery" cssbase="../scripts/jquery/css"/>
            <script type="text/javascript" src="wymeditor/jquery.wymeditor.min.js"></script> 
            <script type="text/javascript" src="edit.js"></script>
            <link rel="stylesheet" type="text/css" href="../scripts/jquery/css/smoothness/jquery.ui.all.css"/>
            <link type="text/css" href="style.css" rel="stylesheet"></link>
            <title>Edit Block</title>
        </head>
        <body>
            <div id="editor">
                <form action="store.xql" id="editor-form" name="editor-form" method="post">
                    <textarea name="note" id="edit-block">
                    { edit:block-to-html() }
                    </textarea>
                    <button type="submit">Save</button>
                    <button id="abort" type="button">Abort</button>
                    <input type="hidden" name="action" value="edit"/>
                    <input type="hidden" name="doc" value="{request:get-parameter('doc', ())}"/>
                    <input type="hidden" name="nodeId" value="{request:get-parameter('nodeId', ())}"/>
                </form>
            </div>
            <div id="tool-dialog">
                <form id="tool-form">
                    <table>
                        <tr>
                            <td>
                                <select id="type" name="type">
                                    <option value="term">Term</option>
                                    <option value="place">Place</option>
                                    <option value="person">Person</option>
                                    <option value="people">People</option>
                                </select>
                            </td>
                            <td><button type="button" name="lookup">Lookup</button></td>
                        </tr>
                        <tr>
                            <td><label for="key">Key:</label></td>
                            <td><input id="key" type="text" name="key" size="50"/></td>
                        </tr>
                        <tr>
                            <td colspan="2"><button id="ok-button" type="submit">OK</button></td>
                        </tr>
                    </table>
                </form>
            </div>
        </body>
    </html>
};

jquery:process(edit:html())