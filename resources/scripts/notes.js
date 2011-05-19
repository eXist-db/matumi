$(document).ready(function() {
    $('.editor-area').wymeditor({
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
            {'name': 'Redo', 'title': 'Redo', 'css': 'wym_tools_redo'},
            {'name': 'CreateLink', 'title': 'Link', 'css': 'wym_tools_link'},
            {'name': 'Unlink', 'title': 'Unlink', 'css': 'wym_tools_unlink'}
          ],
        containersItems: [
             {'name': 'P', 'title': 'Paragraph', 'css': 'wym_containers_p'},
             {'name': 'H1', 'title': 'Heading_1', 'css': 'wym_containers_h1'},
             {'name': 'H1', 'title': 'Heading_2', 'css': 'wym_containers_h2'},
             {'name': 'H1', 'title': 'Heading_3', 'css': 'wym_containers_h3'},
             {'name': 'BLOCKQUOTE', 'title': 'Blockquote', 'css': 'wym_containers_blockquote'},
           ],
        classesHtml: ''     
    });
    
    $('#editor-form').submit(store);
});

function store() {
    jQuery.wymeditors(0).update();
    
    window.opener.reloadDocument();
}