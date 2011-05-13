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
     * 
     * onSelect: callback function, which will be called whenever
     * the user makes a selection. Use this to show a popup, button or
     * link. The callback function receives the Select instance as this,
     * and the x and y position of the
     * mouse pointer at the end of the selection. The object describing the
     * selection has the following properties:
     */  
    Constr = function (container, options) {
        this.options = $.extend({
            mode: "html",
            onSelect: function (selection) { }
        }, options || {});
        
        this.currentSelection = null;
        
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
                if (prev.className == 'ref' || last.className == 'ref') {
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
            var parent = node;
            while (parent != null) {
                if (parent.id) {
                    id = parent.id;
                    break;
                }
                parent = parent.parentNode;
            }
            return { id: id, position: position, start: start, end: end, text: text, node: node };
        },
        
        /**
         * Returns an object containing selection offsets, anchor node and currently
         * selected text. In detail, the object has the following properties:
         *
         * + start: start offset of the selection within the enclosing element.
         * + end: end offset of the selection.
         * + position: the position of the selected node within the parent element.
         * + node: the anchor node which contains the entire selection.
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
            $.log("start: %i end: %i position: %s id: %s node: %o", obj.start, obj.end, obj.position, obj.id, node);
            return obj;
        },
        
        getAnchorNode: function () {
            var selection = this.getSelectedText();
            if (selection) {
                return selection.node;
            }
            return null;
        }
    };
    
    return Constr;
}());