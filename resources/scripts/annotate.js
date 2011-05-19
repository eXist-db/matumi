var current = {
    document: null,
    query: null,
    id: null
};

var selector = null;

var selection = null;

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
    
    $("#document-body").selection({
        idOnly: true,
        ignore: ".ref,.annotation",
        onSelect: function(pageX, pageY) {
            var selection = this.getSelectedText();
            $('#document-view').data("selection", selection);
            if (selection) {
                $('.selection').text(selection.text);
                $('#new-comment').each(function () {
                    var params = {
                        "nodeId": selection.id,
                        "start": selection.start,
                        "end": selection.end,
                        "child": selection.position,
                        "text": selection.text,
                        "doc": current.document
                    };
                    this.href = "annotate.xql?" + jQuery.param(params);
                });
                // display the toolbar close to current mouse position
                $("#inline-toolbar").css({
                    display: '',
                	left: pageX + 8,
                	top: pageY + 8
                });
                setTimeout("$('#inline-toolbar').hide()", 7000);
            } else
            	$("#inline-toolbar").hide();
        }
    });
    
    $('#new-comment').click(function (ev) {
    	ev.preventDefault();
    	openEditor($("#document-body").selection("getAnchorNode"), this.href);
    });
    $('#search-results').css("display", "none");
    $('#search-form').submit(search);
    $('#edit-form').submit(tag);

    $("#inline-toolbar").css({
    	position: "absolute",
    	display: "none"
    });
    resize();
});

function resize() {
	var vspace = $(window).height() - $("#facets").offset().top - 30;
	var hspace = $("#document-view").width() - 300;
	$("#document-body").css({
		overflow: "auto",
		height: vspace + "px",
		width: hspace + "px"
	});
	$("#facets").css({
		overflow: "auto",
		height: vspace + "px"
	});
}

function suggestCallback(node, params) {
    var select = node.parent().parent().find('select[name ^= field]');
    if (select.length == 1) {
        params.field = select.val();
    }
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

function tag() {
    var form = document.forms["edit-form"];
    if (form.elements["id"].value == '' && !checkSelection())
        return false;
    var selection = $('#document-view').data("selection");

    if (selection) {
        form.elements['nodeId'].value = selection.id;
        form.elements['start'].value = selection.start;
        form.elements['end'].value = selection.end;
        form.elements['child'].value = selection.position;
    }

    form.submit();
}

function search(ev) {
	if (ev)
		ev.preventDefault();
    $('#search-results').css("display", "").html("<img class='indicator' src='images/ajax-loader.gif'/>");
    var params = $('#search-form').serialize();
    $("#facets input").each(function () {
    	if (this.checked)
    		params = params + "&facet=" + encodeURIComponent(this.value);
    });
    $.ajax({
    	url: "search.xql",
    	type: "GET",
    	dataType: "html",
    	data: params,
    	success: function (data, status) {
    		$("#facets").replaceWith($("#facets", data));
    		$("#search-results").html($("#results", data));
    		resize();
    		
    		$('#search-results a').click(function () {
                var q = this.search;
                var params = q.split("&");
                current.document = params[0].substring(5);
                current.query = decodeURIComponent(params[1].substring(3));
                current.id = this.hash.substring(2);
                loadDocument();
                return false;
            });
    		var facets = $("#facets");
    		facets.find("input").change(function (ev) {
    			ev.preventDefault();
    			search();
    		});
    		$(".facet li", facets).hover(
    				function () {
    					$(".facet-links", this).show();
    				},
    				function () {
    					$(".facet-links", this).hide();
    				}
    		);
    		$("a.key-search", facets).click(function (ev) {
    	    	ev.preventDefault();
    	    	$(document.forms["search"].elements["field"]).val("Key");
    	    	$(document.forms["search"].elements["q"]).val(this.href);
    	    	search();
    	    });
    		$("#clear-facets").click(function (ev) {
    			facets.find("input").each(function () {
    				this.checked = false;
    			});
    		});
    	}
    });
//    $('#search-results').load('search.xql', params, function (html, status) {
//        $('#search-results a').click(function () {
//        	$.log("Link: %s#%s", this.search, this.hash);
//            var q = this.search;
//            var params = q.split("&");
//            current.document = params[0].substring(5);
//            current.query = decodeURIComponent(params[1].substring(3));
//            current.id = this.hash.substring(2);
//            loadDocument();
//            return false;
//        });
//    });
    return false;
}

function reloadDocument() {
    setTimeout("loadDocument()", 1500);
}

function loadDocument() {
    $.log('Loading document: %s Query: %s Id: %s', current.document, current.query, current.id);
    $.get('.', { doc: current.document, q: current.query, ajax: 'true' }, function (html, status) {
    	$.log("type: %s", typeof html);
    	WYMeditor.INSTANCES = [];
        $('#document-body').html(html);
        resize();
        initLinks();
        if (current.id && current.id.length > 0) {
//            var target = $(document.getElementById(current.id));
//            if (target.length > 0) {
//            	$.log("offset: %s", target.position().top);
//                var offset = target.position().top;
//                $('#document-view').scrollTop(offset);
//            }
        	var target = document.getElementById(current.id);
        	if (target)
        		target.scrollIntoView();
        }
    });
}

function initLinks() {
	var documentView = $("#document-body");
	$("a.name", documentView).tooltip({
		offset: [30, 0],
		position: 'top center',
		relative: false,
		delay: 1000,
		tip: '#dbpedia-tooltip',
		onBeforeShow: function () {
			var trigger = this.getTrigger();
			var tip = this.getTip();
			tip.find("h4").text(trigger.attr("rel"));
			tip.find("a").attr("href", trigger.attr("href"));
			return true;
		}
	});
	$("a.key-search").click(function (ev) {
    	ev.preventDefault();
    	$(document.forms["search"].elements["field"]).val("Key");
    	$(document.forms["search"].elements["q"]).val(this.href);
    	search();
    });
    $("a.annotation").click(function (ev) {
    	ev.preventDefault();
    	openEditor(this, this.href);
    });
    $('a.edit-link').click(function (ev) {
        ev.preventDefault();
        var link = this.previousSibling;
        document.forms["edit-form"].elements["id"].value = this.hash.substring(1);
        document.forms["edit-form"].elements["url"].value =
            link.pathname.substring(link.pathname.lastIndexOf('/') + 1);
        $(document.forms["edit-form"].elements["field"]).val(link.className);
        enableTab('edit-panel');
    });
}

var editorReady = false;

function initAnnotation(container) {
	var editor = $('.editor', container);
	var showEditor = $(".toggle-editor", container);
	if (container.find(".atom-entry").length == 0) {
		showEditor.hide();
		initEditor(container);
	} else {
		showEditor.show();
		editor.hide();
		$('.toggle-editor', container).click(function (ev) {
			ev.preventDefault();
			
			initEditor(container);
			$(this).hide();
			editor.show();
		});
	}
	$('.close-annotations').click(function (ev) {
		ev.preventDefault();
		$(container).remove();
		WYMeditor.INSTANCES = [];
	});
}

function openEditor(node, href) {
	$("#inline-toolbar").hide();
	$("#annotations").remove();
	WYMeditor.INSTANCES = [];
	var block = $(node).closest("p,div,h1,h2,h3,h4,h5,h6");
	$.get(href, null, function (data) {
		var inserted = $(block).after(data);
		document.getElementById("annotations").scrollIntoView();
		initAnnotation($(block).next());
	});
}

function initEditor(container) {
	if (jQuery.wymeditors(0))
		return;
	$('.editor-area', container).wymeditor({
		skin: "compact",
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
	
	$('.editor-form', container).submit(function (ev) {
		ev.preventDefault();
		jQuery.wymeditors(0).update();
		$.post("annotate.xql", $(this).serialize(), function (data) {
			$(".feed", container).replaceWith(data);
			$('.editor', container).hide();
			$(".toggle-editor", container).show();
			
			if (selection) {
				current.id = selection.id;
				$.log("Reloading document %s#%s", current.document, current.id);
				loadDocument();
			}
		});
	});
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

function initTabs(startTab) {
    $('.tabs').each(function () {
        var container = $(this);
        $('ul li a', this).each(function () {
            var target = $(this.hash);
            if (this.hash.substring(1) != startTab)
                target.css('display', 'none');
            var link = $(this);
            link.button().click(function (ev) {
                ev.preventDefault();
                $('> div', container).each(function () {
                    $(this).css('display', 'none');
                });
                target.css('display', '');
            });
        });
    });
}

function enableTab(id) {
    $('.tabs').each(function () {
        $('> div', this).each(function () {
            $(this).css('display', 'none');
        });
    });
    $('#' + id).css('display', '');
}
