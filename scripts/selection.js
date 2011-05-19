var eXist = eXist || {};

/**
 * Define a namespace for clean separation.
 * Based on the module pattern described in
 * "Javascript patterns" by S. Stefanov.
 */
eXist.namespace = function (ns_string) {
    var parts = ns_string.split('.'),
		parent = eXist,
		i;
	if (parts[0] == "eXist") {
		parts = parts.slice(1);
	}
	
	for (i = 0; i < parts.length; i++) {
		// create a property if it doesn't exist
		if (typeof parent[parts[i]] == "undefined") {
			parent[parts[i]] = {};
		}
		parent = parent[parts[i]];
	}
	return parent;
	
}

eXist.namespace("eXist.util.Select");

/**
 * Track text selection.
 */
eXist.util.Select = (function () {
    
    /**
     * Create a new Select object. Takes the following options:
     * 
     * onSelect: callback function, which will be called whenever
     * the user makes a selection. Use this to show a popup, button or
     * link. The callback function receives the Select instance as this,
     * and the x and y position of the mouse pointer at the end of the selection.
     * 
     * ignore: a jquery selector. Nodes matching this selector will be ignored
     * when searching for a reference node. If they contain text, it will also be ignored
     * when computing character offsets. This option is typically used to ignore nodes
     * which were inserted dynamically and are not part of the original document.
     * 
     * idOnly: if set to true, only use elements which have an id as anchor for the selection.
     */  
    Constr = function (container, options) {
        this.options = $.extend({
            onSelect: function (selection) { },
            ignore: null,
            idOnly: true
        }, options || {});
        
        this.currentSelection = null;
        this.container = container;
        
        var $this = this;
        $(container).mouseup(function (ev) {
            $this.currentSelection = null;
            $this.options.onSelect.call($this, ev.pageX, ev.pageY);
        });
    };
    
    Constr.prototype = {
        
        $getSelected: function() {
            if(window.getSelection) { return window.getSelection(); }
            else if(document.getSelection) { return document.getSelection(); }
            else {
                return document.selection && document.selection.createRange();
            }
            return false;
        },
        
        $findParent: function(node, start, end) {
            var text = node.data.substring(start, end);
            
            // if the node containing the selection is not the first child
            // of its parent, we need to determine its position by iterating
            // through the preceding siblings.
            var position = 0;
            var prev = node.previousSibling;
            var last = node;
            while (prev != null) {
                if (this.options.ignore && ($(prev).is(this.options.ignore) || $(last).is(this.options.ignore))) {
                    var prevLen = $(prev).text().length;
                    start += prevLen;
                    end += prevLen;
                } else
                    position++;
                last = prev;
                prev = prev.previousSibling;
            }
            // find closest ancestor with an id
            var id = "";
            if (this.options.idOnly) {
                var parent = node;
                while (parent != null) {
                    if (parent.id) {
                        id = parent.id;
                        break;
                    }
                    parent = parent.parentNode;
                }
            }
            
            var selector = this.$getSelector(node);
            return { id: id, position: position, start: start, end: end, text: text,
                selector: selector };
        },
        
        /**
         * Returns a jquery selector which will select the given node relative to the container
         * element.
         */
        $getSelector: function (node) {
            var path = "";
            var parent = node;
            if (node.nodeName == '#text')
                parent = node.parentNode;
            while (parent && parent.nodeType == 1 && parent != this.container) {
                var idx = $(parent.parentNode).children(parent.tagName).index(parent);
                if (path.length > 0)
                    path = '> ' + path;
                path = parent.tagName.toLowerCase() + ':eq(' + idx + ')' + path;
                parent = parent.parentNode;
            }
            return path;
        },
        
        /**
         * Returns an object containing selection offsets, anchor node and currently
         * selected text. In detail, the object has the following properties:
         *
         * + start: start offset of the selection within the enclosing element.
         * + end: end offset of the selection.
         * + position: the position of the selected child node within the enclosing element.
         * + selector: a jQuery selector to select the enclosing element, relative to the container.
         * Pass this to $() to find the element within the HTML document.
         * + id: the id of the closest ancestor node which has an id attribute.
         */
        getSelectedText: function() {
            if (this.currentSelection) {
                return this.currentSelection;
            }
            var sel = this.$getSelected();
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
            
            var obj = this.$findParent(node, start, end);
            $.log("start: %i end: %i position: %s id: %s node: %o, selector: %s", obj.start, obj.end, 
                obj.position, obj.id, node, obj.selector);
            return obj;
        },
        
        /**
         * Return the node which contains the selection.
         */
        getAnchorNode: function () {
            var selection = this.getSelectedText();
            if (selection) {
                var anchor = $(selection.selector, this.container).contents().eq(selection.position);
                return anchor ? anchor[0] : null;
            }
            return null;
        }
    };
    
    return Constr;
}());

/**
 * jQuery plugin "selection". Wraps around eXist.util.Select.
 */
(function($) {
    methods = {
        init: function (options) {
            return this.each(function () {
                $(this).data("eXist.util.Select", new eXist.util.Select(this, options));
            });
        },
        
        getAnchorNode: function () {
            var select = $(this).data("eXist.util.Select");
            return select.getAnchorNode();
        }
    };
    $.fn.selection = function (method) {
        if (methods[method]) {
            return methods[method].apply(this, Array.prototype.slice.call(arguments, 1));
        } else if (typeof method === 'object' || !method) {
            return methods.init.apply(this, arguments);
        } else {
            alert('Method "' + method + '" not found!');
        }
    };
})(jQuery);

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