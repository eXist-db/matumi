$(document).ready(function() {
    $("#error-message").dialog({
        title: 'An Error Occurred',
        width: 450,
        modal: true,
        autoOpen: false,
        buttons: {
            Ok: function() {
                $(this).dialog('close');
            }
        }        
    });
    $('#annotation-text').ckeditor({
        toolbar: [
            ['Cut','Copy','Paste'],
            ['Undo','Redo','-','Find','Replace','-','SelectAll'],
            ['Bold','Italic','NumberedList','BulletedList','Link','Unlink','Anchor']
        ],
        forcePasteAsPlainText: true,
        height: '90%',
        width: '90%',
        resize_enabled: true
    });
    $('#editor-form').submit(store);
});

function trackSelection() {
    var sel = getSelectedText();
    $('#document-view').data("selection", sel);
    if (sel)
        $('.selection').text(sel.node.data.substring(sel.start, sel.end));
}

function checkSelection() {
    var sel = $('#document-view').data("selection");
    if (sel == null) {
        $('#error-message-text').html('Please select some text to annotate.');
        $('#error-message').dialog("open");
        return false;
    }
    return true;
}

function store() {
    var form = document.forms["editor-form"];
    if (form.elements["id"].value == '' && !checkSelection())
        return false;
    var selection = $('#document-view').data("selection");
    var editor = $('#annotation-text').ckeditorGet();
    editor.updateElement();

    if (selection) {
        form.elements['nodeId'].value = selection.id;
        form.elements['start'].value = selection.start;
        form.elements['end'].value = selection.end;
        form.elements['child'].value = selection.position;
    }
    
    form.submit();
}

function getSelectedText() {
    var sel = getSelected();
    if (sel.isCollapsed)
        return null;

    var node = sel.focusNode;
    var start = sel.anchorOffset;
    var end = sel.focusOffset;
    if(sel.focusNode.nodeName !== '#text') {
        // Is selection spanning more than one node, then select the parent
        if((sel.focusOffset - sel.anchorOffset)>1)
            $.log("Selected spanning more than one: %o", sel.anchorNode);
        else if ( sel.anchorNode.childNodes[sel.anchorOffset].nodeName !== '#text' )
            node = sel.anchorNode.childNodes[sel.anchorOffset];
        else
            node = sel.anchorNode;
        start = 0;
        end = node.nodeValue.length;
    }
    // if we have selected text which does not touch the boundaries of an element
    // the anchorNode and the anchorFocus will be identical
    else if( sel.anchorNode.data === sel.focusNode.data ){
        $.log("Selected non bounding text: %o", sel.anchorNode);
        node = sel.anchorNode;
        start = sel.anchorOffset;
        end = sel.focusOffset;
    }
    // This is the first element, the element defined by anchorNode is non-text.
    // Therefore it is the anchorNode that we want
    else if( sel.anchorOffset === 0 && !sel.anchorNode.data ){
        $.log("Selected whole element at start of paragraph " +
              "(whereby selected element has not text e.g. &lt;script&gt;: %o",sel.anchorNode);
    }
    // If the element is the first child of another (no text appears before it)
    else if( typeof sel.anchorNode.data !== 'undefined'
            && sel.anchorOffset === 0
            && sel.anchorOffset < sel.anchorNode.data.length ){
        $.log("Selected whole element at start of paragraph: %o", sel.anchorNode);
    }
    // If we select text preceeding an element. Then the focusNode becomes that element
    // The difference between selecting the preceeding word is that the anchorOffset is less that the anchorNode.length
    // Thus
    else if( typeof sel.anchorNode.data !== 'undefined'
            && sel.anchorOffset < sel.anchorNode.data.length ){
        $.log("Selected preceeding element text: %o", sel.anchorNode);
        node = sel.anchorNode;
        start = sel.anchorOffset;
    }
    // Selected text which fills an element, i.e. ,.. <b>some text</b> ...
    // The focusNode becomes the suceeding node
    // The previous element length and the anchorOffset will be identical
    // And the focus Offset is greater than zero
    // So basically we are at the end of the preceeding element and have selected 0 of the current.
    else if( typeof sel.anchorNode.data !== 'undefined'
            && sel.anchorOffset === sel.anchorNode.data.length
            && sel.focusOffset === 0 ){
        node = sel.focusNode.previousSibling.firstChild;
        start = 0;
        $.log("Selected whole element text: %o", node);
        end = node.nodeValue.length;
    }
    // if the suceeding text, i.e. it bounds an element on the left
    // the anchorNode will be the preceeding element
    // the focusNode will belong to the selected text
    else if(sel.focusOffset > 0) {
        $.log("Selected suceeding element text: %o", sel.focusNode);
        node = sel.focusNode;
        start = 0;
        end = sel.focusOffset;
    }

    var obj = findParent(node, start, end);
    $.log("start: %i end: %i position: %s id: %s node: %o", obj.start, obj.end, obj.position, obj.id, node);
    return obj;
}

/*
    For the selection text, find the closest ancestor node with an id.
    @return an object containing the properties "id", "position", "start",
    "end", where "id" is the node id of the closest parent, "position" is
    the position of the node containing the selection within the child nodes
    of its parent, "start" is the start and "end" is the end offset.
 */
function findParent(node, start, end) {
	alert("HELLO");
    // if the node containing the selection is not the first child
    // of its parent, we need to determine its position by iterating
    // through the preceding siblings.
    var position = 0;
    var prev = node.previousSibling;
    while (prev != null) {
        if (prev.className != 'ref')
            position++;
        else
        	$.log("skipping ref");
        prev = prev.previousSibling;
    }
    // find closest ancestor with an id
    var id = "";
    var parent = node;
    while (parent != null) {
        if (parent.id) {
            id = parent.id;
            break;
        }
        parent = parent.parentNode;
    }
    return { id: id, position: position, start: start, end: end, node: node };
}

/* attempt to find a text selection */
function getSelected() {
    if(window.getSelection) { return window.getSelection(); }
    else if(document.getSelection) { return document.getSelection(); }
    else {
        return document.selection && document.selection.createRange();
    }
    return false;
}

/* Debug and logging functions */
(function($) {
    $.log = function() {
        if(window.console && window.console.log) {
            console.log.apply(window.console,arguments)
        }
    };
    $.fn.log = function() {
        $.log(this);
        return this
    }
})(jQuery);