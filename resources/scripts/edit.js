var editor = null;

head.ready(function() {
    $("#tool-dialog").dialog({
        title: 'Edit/Insert Term',
        width: 450,
        modal: true,
        autoOpen: false,
        open: openToolDialog
    });
    $("#ok-button").click(submitToolDialog);
    
    $('#edit-block').wymeditor({
        toolsItems: [
            {'name': 'Bold', 'title': 'Strong', 'css': 'wym_tools_strong'}, 
            {'name': 'Italic', 'title': 'Emphasis', 'css': 'wym_tools_emphasis'},
            {'name': 'Superscript', 'title': 'Superscript', 'css': 'wym_tools_superscript'},
            {'name': 'Subscript', 'title': 'Subscript', 'css': 'wym_tools_subscript'},
            {'name': 'InsertOrderedList', 'title': 'Ordered_List', 'css': 'wym_tools_ordered_list'},
            {'name': 'InsertUnorderedList', 'title': 'Unordered_List', 'css': 'wym_tools_unordered_list'},
            {'name': 'Indent', 'title': 'Indent', 'css': 'wym_tools_indent'},
            {'name': 'Outdent', 'title': 'Outdent', 'css': 'wym_tools_outdent'},
            {'name': 'Undo', 'title': 'Undo', 'css': 'wym_tools_undo'},
            {'name': 'Redo', 'title': 'Redo', 'css': 'wym_tools_redo'}
          ],
        containersItems: [],
        postInit: function(wym) {
            editor = wym;
            var html = "<li class='wym_tools_wrap'>"
                     + "<a href='#' title='Wrap' style='background-image: url(images/link_edit.png); background-position: center center;'>"
                     + "Edit/Insert Term"
                     + "</a></li>";
            $(wym._box).find(wym._options.toolsSelector + wym._options.toolsListSelector).append(html);
            
            $(wym._box).find('li.wym_tools_wrap a').click(function() {
                $('#tool-dialog').dialog("open");
                return(false);
            });
        },
        classesHtml: '',
        containersHtml: ''
    });
    $("#abort").click(function() {
        window.close();
    });
    $('#editor-form').submit(store);
});

function openToolDialog() {
    var container = editor.container();
    if (container.nodeName == 'A') {
        $('#type').val(container.className);
        $('#key').val(container.href);
    }
    editor.status(editor.container().nodeName);
}

function submitToolDialog(ev) {
    ev.preventDefault();
    
    var type = $("#type").val();
    var key = $("#key").val();
    var container = editor.container();
    if (container.nodeName == 'A') {
        container.className = type;
        container.href = key;
    } else {
        editor.wrap("<a class='" + type + "' href='#" + key + "'>", "</a>");
    }
    
    $("#tool-dialog").dialog("close");
}

function store() {
    jQuery.wymeditors(0).update();
    
    window.opener.reloadDocument();
}