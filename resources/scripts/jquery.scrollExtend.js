/*
 * jQuery scrollExtend plugin v1.0.1
 * 
 * Copyright (c) 2009 Jim Keller
 * Context - http://www.contextllc.com
 * 
 * Dual licensed under the MIT and GPL licenses.
 *
 */

//
// onScrollBeyond
//	
jQuery.fn.onScrollBeyond = function(callback, options) {	
	var domTargetElement = this;

	if ( callback == 'disable' ) { 
		jQuery(domTargetElement).data('onScrollBeyond-disabled', true);
		return;
	}	
	if ( callback == 'enable' ) {
		jQuery(domTargetElement).data('onScrollBeyond-disabled', false);
		return;
	}
	
	
	//
	// Main Body
	//
       var settings = {
       	'buffer': 20,
       	'fireOnDocEnd': true,
       	'fireOnBeyondElement' : true
         },
         $document = jQuery(document),
         $window =   jQuery(window);
	

	jQuery.extend(settings, options);
	jQuery(window).bind('scroll', function() {

			var fire = false,
			    jqTargetElement = jQuery(domTargetElement),
			    document_scrollTop = $document.scrollTop(),
			    top = jqTargetElement.position().top;

			if ( jqTargetElement.data('onScrollBeyond-disabled') == true ) {return; }			
			if ( settings.fireOnBeyondElement ) {				
				// if element has scrolled off the screen, even if other elements exist below it
				if ( document_scrollTop > ( top + jqTargetElement.height()) ) {	fire = true;}			
			}
			
			if ( !fire && settings.fireOnDocEnd ) {			
				var amt_scrolled = document_scrollTop - top ;				
				// if the amount of the element we already scrolled beyond + its top position on the document + the window height + some buffer is greater than the total doc height
				if ( (amt_scrolled + top + $window.height() + settings.buffer) > $document.height() ) {	fire = true;}
			}
			
			if ( fire ) {
				callback.call(this, domTargetElement);
			}
		}		
   );       	
   return this;
};


//
// scrollExtend
//
jQuery.fn.scrollExtend = function(options) {
	var $this = jQuery(this);
	//
	// Special actions
	if ( options == 'disable' ) {
		$this.data('scrollExtend-disabled', true);
		return;
	}
	
	if ( options == 'enable' ) {
		$this.data('scrollExtend-disabled', false);
		return;
	}	
	if( !$this.data('page') ){  $this.data('page',1) }
	
    var settings = {
       	'url': null,
       	'target': null, 
	    'loadingIndicatorEnabled': true,
       	'loadingIndicatorClass': 'loadingIndicator',
	    'newElementClass': '',
       	'beforeStart': function(){ return true},
       	'onSuccess':  function(){ return true},
	    'ajaxSettings': {}
    },

	url,
    jqLoadingElem = null,
    localAjaxSettings = {},
    ajaxSettings = settings.ajaxSettings;
    	
    jQuery.extend(settings, options);
	jQuery.extend(ajaxSettings, settings.ajaxSettings);		

	jQuery(this).onScrollBeyond(
		function(container) {		
			var jqContainerElem = jQuery(container);

			//
			// Make sure scrollExtend wasn't explicitly disabled,
			// and that we're not already loading a new element
			//
			if ( jqContainerElem.data('scrollExtend-disabled') != true && jqContainerElem.data('scrollExtendLoading') != true ) {
			
				jqContainerElem.data('scrollExtendLoading', true);
				
				if ( typeof(settings.beforeStart) == 'function' ) {
					if ( !settings.beforeStart.call(this, container) ) {
						jqContainerElem.data('scrollExtendLoading', false);
						return;
					}
				}			
				//
				// Check the disabled flag again in case it was changed during the beforeStart callback
				if ( jqContainerElem.data('scrollExtend-disabled') == true ) {
					jqContainerElem.data('scrollExtendLoading', false);
					return;
				}
				//
				// Set the URL
				ajaxSettings.url = typeof(settings.url) == 'function' ? settings.url.call(container, container, settings ) : settings.url;
			
				//
				// Set up our new element
				var target =  settings.target || container;
				var new_elem = ( container.is('table') ) ? jQuery('<tbody/>') : jQuery('<div/>');
			
				if ( settings.newElementClass != '' ) {
					jQuery(new_elem).addClass( settings.newElementClass );
				}

				//
				// Add loading indicator
				if ( settings.loadingIndicatorEnabled ) {
				   container.addClass(settings.loadingIndicatorClass ); // = $('<div class="' + settings.loadingIndicatorClass  +  '"/>').appendTo(target);
				}
				
				
				if( ajaxSettings.url ) {  
				     var target = ( settings.target ) ? settings.target : container;
				     $(target).load( ajaxSettings.url, function( responseText, textStatus, XMLHttpRequest){
						if (status == "error") {						
						}else {
    						var beforeOK = settings.onSuccess.call( this, responseText, $(target), container );
                            if ( settings.loadingIndicatorEnabled ) { container.removeClass( settings.loadingIndicatorClass ) }        				    
        					jQuery(container).data('scrollExtendLoading', false);
				       }
				     })				     
                }else{
                   if ( settings.loadingIndicatorEnabled ) { container.removeClass( settings.loadingIndicatorClass ) }        				    
        			jQuery(container).data('scrollExtendLoading', false);
                }
			}
		},
		settings
	);
       
    return this;

};

