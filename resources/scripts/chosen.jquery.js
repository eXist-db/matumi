(function() {
  /*
  Chosen, a Select Box Enhancer for jQuery and Protoype
  by Patrick Filler for Harvest, http://getharvest.com
  
  Available for use under the MIT License, http://en.wikipedia.org/wiki/MIT_License
  
  Copyright (c) 2011 by Harvest
  */  
  
  String.prototype.escapeBadPath = function(){
     return this.replace(/([ #;&,.+*~\':"!^$[\]()=>|\/])/g,'\\$1'); 
  }
  
  var $, Chosen, SelectParser, get_side_border_padding, root;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  root = typeof exports !== "undefined" && exports !== null ? exports : this;
  $ = jQuery;
  $.fn.extend({
    chosen: function(data, options) {
      return $(this).each(function(input_field) {
        if (!($(this)).hasClass("chzn-done")) {
          return new Chosen(this, data, options);
        }
      });
    }
  });
  Chosen = (function() {
    function Chosen(elmn, data, extraOptions) {
      this.set_default_values( extraOptions );
      this.form_field = elmn;
      this.form_field_jq = $(this.form_field);
      this.is_multiple = !!elmn.multiple; // make it boolean
      this.default_text_default = this.form_field.multiple ? "Select Some Options" : "Select an Option";
      this.set_up_html();
      this.register_observers();
      this.form_field_jq.addClass("chzn-done");
      this.container.removeClass('not-ready');
    }
    Chosen.prototype.set_default_values = function( options ) {
      $.extend(this, Chosen.prototype.defauls, options );	  
	  this.click_test_action = __bind(function(evt) {
        return this.test_active_click(evt);
      }, this);
      return true;
/*	  
	  this.active_field = false;
      this.mouse_on_container = false;
      this.results_showing = false;
      this.result_highlighted = null;
      this.result_single_selected = null;
      return this.choices = 0;
*/	  
    };
    Chosen.prototype.set_up_html = function() {
      var container_div, dd_top, dd_width, sf_width;
      this.container_id = this.form_field.id + "_chzn";
      this.f_width = this.form_field_jq.width();
      this.default_text = this.form_field_jq.attr('title') ? this.form_field_jq.attr('title') : this.default_text_default;
      container_div = $("<div />", {
        id: this.container_id,
        "class": 'chzn-container not-ready',
        style: 'width: ' + this.f_width + 'px;'
      });
      if (this.is_multiple) {
        container_div.html('<ul class="chzn-choices">' + 
	                         '<li class="search-field">'+
							   '<input type="text" value="' + this.default_text + '" class="default" style="width:25px;" />'+
							 '</li>' + 
							'</ul>'+
							'<div class="chzn-drop" style="left:-9000px;">'+
							  '<ul class="chzn-results"></ul>'+
							'</div>');
      } else {
        container_div.html('<a href="#" class="chzn-single"><span>' + this.default_text + '</span><div><b></b></div></a><div class="chzn-drop" style="left:-9000px;"><div class="chzn-search"><input type="text" /></div><ul class="chzn-results"></ul></div>');
      }
      this.form_field_jq.css({position:'absolute', left:'-5000px'}).after(container_div);  //.hide()
      this.container = $('#' + this.container_id);
      this.container.addClass("chzn-container-" + (this.is_multiple ? "multi" : "single"));
      this.dropdown = this.container.find('div.chzn-drop').first();
      dd_top = this.container.height();
      dd_width = this.f_width - get_side_border_padding(this.dropdown);
      this.dropdown.css({
        "width": dd_width + "px",
        "top": dd_top + "px"
      });
      this.search_field = this.container.find('input').first();
      this.search_results = this.container.find('ul.chzn-results').first();
      this.search_field_scale();
      this.search_no_results = this.container.find('li.no-results').first();
      if (this.is_multiple) {
        this.search_choices = this.container.find('ul.chzn-choices').first();
        this.search_container = this.container.find('li.search-field').first();
      } else {
        this.search_container = this.container.find('div.chzn-search').first();
        this.selected_item = this.container.find('.chzn-single').first();
        sf_width = dd_width - get_side_border_padding(this.search_container) - get_side_border_padding(this.search_field);
        this.search_field.css({
          "width": sf_width + "px"
        });
      }
      this.results_build();
      return this.set_tab_index();
    };
   
    Chosen.prototype.register_observers = function() {
      this.container.click(__bind(function(evt) {      return this.container_click(evt);  }, this));
      this.container.mouseenter(__bind(function(evt) {   return this.mouse_enter(evt);   }, this));
      this.container.mouseleave(__bind(function(evt) {  return this.mouse_leave(evt);  }, this));
	 
      this.dropdown.click(__bind(function(evt) {     return this.search_results_click(evt);   }, this));
	  //$('.chzn-results li.active-result, .chzn-results li.active-result * ').live('click',__bind(function(evt) {  return this.search_results_click(evt);  }, this));
	  
      //this.dropdown.mouseover(__bind(function(evt) { return this.search_results_mouseover(evt); }, this));
      $('.chzn-results li.active-result').live('mouseover', __bind(function(evt) { return this.search_results_mouseover(evt); }, this));
      
	  
	  //this.dropdown.mouseout(__bind(function(evt) {  return this.search_results_mouseout(evt);  }, this));
      $('.chzn-results li.active-result').live('mouseout', __bind(function(evt) {  return this.search_results_mouseout(evt);  }, this));
     
	
	  this.form_field_jq.bind("liszt:updated", __bind(function(evt) {
        return this.results_update_field(evt);
      }, this));
	  
      this.search_field.blur(__bind(function(evt) {
        return this.input_blur(evt);
      }, this));
      this.search_field.keyup(__bind(function(evt) {
        return this.keyup_checker(evt);
      }, this));
      this.search_field.keydown(__bind(function(evt) {
        return this.keydown_checker(evt);
      }, this));
	  
      if (this.is_multiple) {
        this.search_choices.click(__bind(function(evt) {
          return this.choices_click(evt);
        }, this));
        return this.search_field.focus(__bind(function(evt) {
          return this.input_focus(evt);
        }, this));
      } else {
        return this.selected_item.focus(__bind(function(evt) {
          return this.activate_field(evt);
        }, this));
      }
    };
    Chosen.prototype.container_click = function(evt) {
      if (evt && evt.type === "click") {
        evt.stopPropagation();
      }
      if (!this.pending_destroy_click) {
        if (!this.active_field) {
          if (this.is_multiple) {
            this.search_field.val("");
          }
          $(document).click(this.click_test_action);
          this.results_show( true );
        } else if (!this.is_multiple && evt && ($(evt.target) === this.selected_item || $(evt.target).parents("a.chzn-single").length)) {
          evt.preventDefault();
          this.results_toggle();
        }
        return this.activate_field();
      } else {
        return this.pending_destroy_click = false;
      }
    };
    Chosen.prototype.mouse_enter = function() {
      return this.mouse_on_container = true;
    };
    Chosen.prototype.mouse_leave = function() {
      return this.mouse_on_container = false;
    };
    Chosen.prototype.input_focus = function(evt) {
      if (!this.active_field) {
        return setTimeout((__bind(function() {
          return this.container_click();
        }, this)), 50);
      }
    };
    Chosen.prototype.input_blur = function(evt) {
      if (!this.mouse_on_container) {
        this.active_field = false;
        return setTimeout((__bind(function() {
          return this.blur_test();
        }, this)), 100);
      }
    };
    Chosen.prototype.blur_test = function(evt) {
      if (!this.active_field && this.container.hasClass("chzn-container-active")) {
        return this.close_field();
      }
    };
    Chosen.prototype.close_field = function() {
      $(document).unbind("click", this.click_test_action);
      if (!this.is_multiple) {
        this.selected_item.attr("tabindex", this.search_field.attr("tabindex"));
        this.search_field.attr("tabindex", -1);
      }
      this.active_field = false;
      this.results_hide();
      this.container.removeClass("chzn-container-active");
      this.winnow_results_clear();
      this.clear_backstroke();
      this.show_search_field_default();
      return this.search_field_scale();
    };
    Chosen.prototype.activate_field = function() {
      if (!this.is_multiple && !this.active_field) {
        this.search_field.attr("tabindex", this.selected_item.attr("tabindex"));
        this.selected_item.attr("tabindex", -1);
      }
      this.container.addClass("chzn-container-active");
      this.active_field = true;
      this.search_field.val(this.search_field.val());
      return this.search_field.focus();
    };
    Chosen.prototype.test_active_click = function(evt) {
      if ($(evt.target).parents('#' + this.container.id).length) {
        return this.active_field = true;
      } else {
        return this.close_field();
      }
    };
	
	// pass grouped data as a parammeter

	// TW
	Chosen.prototype.getOptionData = function( id, li, gr ) {
	    if( this.results_data.groupedData ){
		   var ID = id ? id.substr(id.lastIndexOf("__") + 2).split('_') : [] ;
		   gr = typeof ID[0] != 'undefined'? ID[0] : gr;
		   li = typeof ID[1] != 'undefined'? ID[1] : li;
		   return ( li === -1 ) ? this.results_data[gr] : this.results_data[gr].options[li];
		}else {
		   li = li || id.substr(id.lastIndexOf("_") + 1) ;
		   return this.results_data[ li ];
		}	
	}
	
	Chosen.prototype.setOptionSelected = function( id, state ) {
        if( id ){
		   var optionData = this.getOptionData( id ),
		       key = optionData.value.split('/').join('\\/'),
		       key = optionData.value.replace(/\//g,'\\/'),
		       option =  this.results_data.groupedData ? $( 'optgroup', this.form_field_jq).eq(optionData.group_index).find('option').eq(optionData.options_index):
		                                                 $( 'option', this.form_field_jq ).eq(optionData.options_index);		   
		   if( state ){
				   option.attr('selected', state ); 
		   }else{  option.removeAttr('selected' ); }		   
		}
	}
	
	Chosen.prototype.makeID = function(type, p1, p2 ) {
	   var id; 	   
	   switch( type){
	      case 'groupContainer':  id =  'gC_' + p1 ; break;
	      case 'groupTitle': id = 'gUL_t_' + p1; break;
	      case 'groupUL':    id = 'gUL_' + p1; break;
	      case 'groupLI' : 	 id = 'li__' + p1 + '_' + p2 ; break;
	      case 'LI' : 	     id = 'li_' + p1 ; break;
		  case 'groupChoiceLI' :  id = 'c_' + p1 + '_' + p2 ; break;		  
	      default :          id = 'unknown_' + p1 +'_' + p2; break;	   
	   };       	   
	   return this.container_id + '_' + id;
	};
		
	Chosen.prototype.results_build_group_UL_list = function( oGroup, options , UL, LI, batch ) {	   
	   var originalUL;
		if( !options || (oGroup && oGroup.empty )) { return; }
	   if( oGroup ) { 
	      oGroup.dom_id = this.makeID('groupContainer', oGroup.group_index	);	
			originalUL = $('#'+ oGroup.dom_id +' ul');
			UL = $('<ul class="group"/>');
	   }else{
		   originalUL = UL;
			UL = $('<ul class="flat"/>');
		}
		
		//var workingUL 
		//$('<ul class="group"/>')
		for ( var _i = 0, _len = options.length; _i < _len; _i++) {
			if( batch && this.buildBatch != batch ) return;
			var data = options[_i];  
			if ( data.empty || data.disabled) continue;
			
			var dom_id = data.dom_id = oGroup ? this.makeID('groupLI', data.group_index, data.options_index ):
			                                    this.makeID('LI',      data.options_index ); 
			UL.append(LI.clone(true,true)
				 .attr('id', dom_id)
				 .addClass( data.selected ? 'result-selected' :' active-result' + (oGroup ? ' group-option ': ' flat-option') + ( _i % 2 ? ' odd':' even'  ) ) 
				 .find('div').text(data.text).end()
			 );
			 if (data.selected && this.is_multiple) {
				this.choice_build( data, oGroup );			
			 }
		  }
		  originalUL.replaceWith(UL);
	};
	
	// TODO use http://stackoverflow.com/questions/1095263/how-do-i-chain-or-queue-custom-functions-using-jquery
	Chosen.prototype.results_build_asynch_by_group = function( aGroups, UL, LI, batch, total, pass  ) {
		 if( !aGroups || !aGroups.length ){
			this.show_search_field_default();
			this.parsing = false;
			return;
		 }
		 pass  = (pass || 0) + 1;
		 total = total || parseInt(aGroups.total || ( aGroups.options ? aGroups.options.length : 1 ));
		 
		 this.search_field.val(total); 
		 if( this.results_data.groupedData ){
				var group = aGroups.shift();
				this.results_build_group_UL_list(group, group.options, null, LI, batch  );
				total -= group.options.length;
		 }else{
				this.results_build_group_UL_list(null, aGroups, UL, LI, batch );
				total=0;
		 }	     
		 if( this.buildBatch == batch) {
			 this.buildTimer = setTimeout((__bind(function() {
				this.results_build_asynch_by_group( this.results_data.groupedData?aGroups:null, UL, LI, batch, total, pass );
			 }, this)), 5);
		  };
	};
	

    Chosen.prototype.results_build = function() {
      var startTime, _i, _len, _ref;
      startTime = new Date();
      this.parsing = true;
      //this.results_data = SelectParser.select_to_array(this.form_field);
	  this.results_data_grouped =  this.results_data =  SelectParser.select_to_grouped_array(this.form_field);
      if (this.is_multiple && this.choices > 0) {
        this.search_choices.find("li.search-choice").remove();
        this.choices = 0;
      } else if (!this.is_multiple) {
        this.selected_item.find("span").text(this.default_text);
      }

	 var ul_container = $('<div class="chzn-results"/>'),   // this.search_results.empty().clone();
		li_group  = $('<li id="group.dom_id" class="group-result"><div></div></li>'),
		li_option = $('<li id="option.dom_id" class=""><div/><span/></li>'),
		ul_group  =  $('<ul class="group"/>'),
        div_group  = $('<div class="group-ul"/>'), // .append(ul_group);
        groups = this.results_data_grouped;
        
		if( groups.groupedData ) {
			for ( var g = 0, gL= groups.length ; g < gL; g++) {
			  var ul = $('<ul class="group"/>'), 
				  group = groups[g],
				  groupCont = $('<div class="group-cont" id="'+ this.makeID('groupContainer', g)   + '">'+
								 '<div class="groupTitle">'+ group.label + '</div></div>')
							   .append( ul );
			  	
			  if( !this.asynchGroups ){
				  this.results_build_group_UL_list(group, group.options, ul, li_option )
			  } 
			  groupCont.appendTo(ul_container);		          
		  }	
      }else{
	      var ul = $('<ul class="flat"/>');
		  if( this.asynchGroups ) {
		  
		  }else{
		     this.results_build_group_UL_list(null, groups, ul, li_option );
		  }
          ul.appendTo(ul_container);	
      }	  

      this.show_search_field_default();
      this.search_field_scale();
      this.search_results.replaceWith( ul_container );
	  this.search_results = ul_container;
	
      if( this.asynchGroups ){	  
	      clearTimeout(this.buildTimer);
		   this.results_build_asynch_by_group( $.extend([], this.results_data), ul, li_option, 
					(this.buildBatch = (new Date).getTime()),
					this.results_data_grouped.total
		   );	
	  }else {
         return this.parsing = false;
	  }
    };
	// TW - end

    Chosen.prototype.results_update_field = function() {
      this.result_clear_highlight();
      this.result_single_selected = null;
      return this.results_build();
    };
    Chosen.prototype.result_do_highlight = function(el) {
      var high_bottom, high_top, maxHeight, visible_bottom, visible_top;
      if (el.length) {
        this.result_clear_highlight();
        this.result_highlight = el;
        this.result_highlight.addClass("highlighted");
        maxHeight = parseInt(this.search_results.css("maxHeight"), 10);
		maxHeight = String(maxHeight) == 'NaN' ? this.maxHeight: maxHeight;
        visible_top = this.search_results.scrollTop();
        visible_bottom = maxHeight + visible_top;
        high_top = this.result_highlight.position().top + this.search_results.scrollTop();
        high_bottom = high_top + this.result_highlight.outerHeight();
        if (high_bottom >= visible_bottom) {
          return this.search_results.scrollTop((high_bottom - maxHeight) > 0 ? high_bottom - maxHeight : 0);
        } else if (high_top < visible_top) {
          return this.search_results.scrollTop(high_top);
        }
      }
    };
    Chosen.prototype.result_clear_highlight = function() {
      if (this.result_highlight) {
        this.result_highlight.removeClass("highlighted");
      }
      return this.result_highlight = null;
    };
    Chosen.prototype.results_toggle = function() {
      if (this.results_showing) {
        return this.results_hide();
      } else {
        return this.results_show();
      }
    };
    Chosen.prototype.results_show = function( firstClick ) {
      var dd_top;
      if (!this.is_multiple) {
        this.selected_item.addClass("chzn-single-with-drop");
        if (this.result_single_selected) {
          this.result_do_highlight(this.result_single_selected);
        }
      }
      dd_top = this.is_multiple ? this.container.height() : this.container.height() - 1;
      this.dropdown.css({  "top": dd_top + "px",  "left": 0  });
      this.results_showing = true;
      this.search_field.focus();
      this.search_field.val(this.search_field.val());
      return this.winnow_results( firstClick );
    };
	
    Chosen.prototype.results_hide = function() {
      if (!this.is_multiple) {
        this.selected_item.removeClass("chzn-single-with-drop");
      }
      this.result_clear_highlight();
      this.dropdown.css({ "left": "-9000px"});
      return this.results_showing = false;
    };
    Chosen.prototype.set_tab_index = function(el) {
      var ti;
      if (this.form_field_jq.attr("tabindex")) {
        ti = this.form_field_jq.attr("tabindex");
        this.form_field_jq.attr("tabindex", -1);
        if (this.is_multiple) {
          return this.search_field.attr("tabindex", ti);
        } else {
          this.selected_item.attr("tabindex", ti);
          return this.search_field.attr("tabindex", -1);
        }
      }
    };
    Chosen.prototype.show_search_field_default = function() {
      if (this.is_multiple && this.choices < 1 && !this.active_field) {
        this.search_field.val(this.default_text);
        return this.search_field.addClass("default");
      } else {
        this.search_field.val("");
        return this.search_field.removeClass("default");
      }
    };
    Chosen.prototype.search_results_click = function(evt) {
      var target = $(evt.target).closest(".active-result");
      if (target.length) {        
        return this.result_select( this.result_highlight = target );
      }
    };
    Chosen.prototype.search_results_mouseover = function(evt) {
        return this.result_do_highlight($(evt.target).closest(".active-result"));
    };
    Chosen.prototype.search_results_mouseout = function(evt) {
        return this.result_clear_highlight( $(evt.target).closest(".active-result") );
    };
    Chosen.prototype.choices_click = function(evt) {
      evt.preventDefault();
      if (this.active_field && !($(evt.target).hasClass("search-choice" || $(evt.target).parents('.search-choice').first)) && !this.results_showing) {
        return this.results_show();
      }
    };
	 
	 // To Do 
	 Chosen.prototype.LIchoice = $('<li class="search-choice" id="dummi">' + 
                         		     '<span class="group-label"></span>' +  									
										     '<span class="choice-text"></span>' +
										    '<a href="#" class="search-choice-close" rel=""></a></li>');
/*	 Chosen.prototype.LIchoice.find("a").first().click(__bind(function(evt) {
        return Chosen.choice_destroy_link_click(evt);
      }, Chosen.prototype));										 
	*/										 
    Chosen.prototype.choice_build = function(item, group ) {
      var choice_id, link, pos = group ? ( item.group_index + '_' + item.options_index ) : item.options_index;
      choice_id = this.makeID( 'groupChoiceLI', item.group_index, item.options_index );
      this.choices += 1;		
      this.search_container.before('<li class="search-choice" id="' + choice_id + '">' + 
                         		        (group ? ( '<span class="group-label">'+ group.label + '</span>:'):'') +  									
										'<span class="choice-text">' + item.text + 	'</span>' +
										'<a href="#" class="search-choice-close" rel="' + pos + '"></a></li>');
										
      return $('#' + choice_id).find("a:first").click(__bind(function(evt) {
        return this.choice_destroy_link_click(evt);
      }, this));
    };
    Chosen.prototype.choice_destroy_link_click = function(evt) {
      evt.preventDefault();
      this.pending_destroy_click = true;
      return this.choice_destroy($(evt.target));
    };
    Chosen.prototype.choice_destroy = function(link) {
      this.choices -= 1;
      this.show_search_field_default();
      if (this.is_multiple && this.choices > 0 && this.search_field.val().length < 1) {
        this.results_hide();
      }
      this.result_deselect(link.attr("rel"));
      return link.closest('li').remove();
    };
    Chosen.prototype.result_select = function( LI ) {
      var high, high_id, item;
      if (this.result_highlight) {
        high = this.result_highlight;
        high_id = high.attr("id");
        this.result_clear_highlight();
        high.addClass("result-selected");
        if (this.is_multiple) {
          this.result_deactivate(high);
        } else {
          this.result_single_selected = high;
        }
        item = this.getOptionData( high_id );		
        item.selected = true;
        this.setOptionSelected( high_id, true );
        if (this.is_multiple) {            
		   this.choice_build( item, item.group_index != -1 ? this.getOptionData( null, -1, item.group_index  ):null);		                                                     
        } else {
           this.selected_item.find("span").first().text(item.text);
        }
        this.results_hide();
        this.search_field.val("");
        this.form_field_jq.trigger("change");
        return this.search_field_scale();
      }
    };
    Chosen.prototype.result_activate = function(el) {
      if( !el.hasClass('active-result')) {
	     el.addClass("active-result"); //.show();
	  }
	  return el;
    };
    Chosen.prototype.result_deactivate = function(el) {
	  if( el.hasClass('active-result')) {
	   el.removeClass("active-result"); //.hide();
	  }
	  return el;
    };
    Chosen.prototype.result_deselect = function(pos) {
      var IDs = pos.split('_'),
          result_data = this.getOptionData(  null, IDs[1] || IDs[0], typeof IDs[1] != 'undefined' ? IDs[0] : null );
		  
      result_data.selected = false;
	  this.setOptionSelected( IDs[1]? ('__' + pos):('_' + pos), false );
      this.result_activate( $("#" +  result_data.dom_id ).removeClass("result-selected"));
      this.result_clear_highlight();
      this.winnow_results();
      this.form_field_jq.trigger("change");
      return this.search_field_scale();
    };
    Chosen.prototype.results_search = function(evt) {
      if (this.results_showing) {
        return this.winnow_results();
      } else {
        return this.results_show();
      }
    };
    
    
    Chosen.prototype.winnow_results_display_group = function(  options, searchText, regex, zregex, batch ) {
      var results = 0, 
          ul = $("#" + options[0].dom_id).closest('ul'), 
          UL = ul.clone(true,true);
      
      for( var o=0, lenOp = options.length; o < lenOp; o++ ){
		     if( batch && this.searchBatch != batch ) { return results}
			 var option = options[o];
             if (option.disabled || option.empty || option.selected || !this.is_multiple  ) { continue; }
		     var $item = $("#" + (option.dom_id), UL);
			 if( !$item.length  ){ continue;  }
		
			 var testX = option.text.search(regex); // regex.test(option.text);
			 var testZ = option.text.search(zregex); 
			
			 if (testZ > -1 ) {
				results++;			  
 				var startpos = option.text.search(zregex), 
					    t = option.text,
						text = [ t.substr(0, startpos), '<em><b>', 
								 t.substr(startpos, searchText.length), '</b></em>',
								 t.substr(startpos + searchText.length)].join('');
								 
                $item.addClass('patial-match').find('span').html( text );
				this.result_activate( $item, option );
			} else {
			  if (this.result_highlight && option.dom_id === this.result_highlight.attr('id') ) {
				  this.result_clear_highlight();
			  }
			  this.result_deactivate( $item.removeClass('patial-match') );
			}                
       }
       ul.replaceWith(UL);
       return results;
    };
    
	
	Chosen.prototype.winnow_results_asynch_by_group = function( aGroups, searchText, regex, zregex, results, batch  ) {
		 results = results || 0;
         if( this.searchBatch != batch) { return results} ;// another search has started
		 if( !aGroups || !aGroups.length ){
			return (results < 1 && searchText.length) ?
				  this.no_results(searchText):
			      this.winnow_results_set_highlight();
		 }
		 if( this.results_data.groupedData ){
		    var group = aGroups.shift(), visibleInThisGroup=0;
		    visibleInThisGroup = this.winnow_results_display_group( group.options, searchText, regex, zregex, batch  );			
			if( this.searchBatch != batch) { return results} 
			if( !visibleInThisGroup ) {
    		      $("#" + group.dom_id).hide();
    		}else $("#" + group.dom_id).show(); 
			results += visibleInThisGroup;
		 }else{
		    results = this.winnow_results_display_group( aGroups, searchText, regex, zregex, batch  );
		 }
		 if( this.searchBatch == batch) { 
			 this.searchTimer =  setTimeout((__bind(function() {
				this.winnow_results_asynch_by_group(  this.results_data.groupedData ?aGroups:null, searchText, regex, zregex, results, batch );
			 }, this)), 15);	
		}
         return results;	     
	};
	
    Chosen.prototype.winnow_results = function( firstClick ) {
      var part, parts,  results=0, startTime = new Date(),
          searchText = this.search_field.val() === this.default_text ? "" : $.trim(this.search_field.val()),
		  regex = new RegExp('^' + searchText.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&"), 'i'),
          zregex = new RegExp(searchText.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&"), 'i');
		  
      this.no_results_clear();
	  if( !searchText) {
	     $('li.patial-match', this.dropdown ).removeClass('patial-match');
		 $('li:not(.active-result):not(.result-selected)', this.dropdown).addClass('active-result');
	     $('.group-cont', this.dropdown).show();
		 return;	  
	  }	 
	  if( this.asynchSearch ){
	      clearTimeout(this.searchTimer);
		  this.searchBatch = (new Date).getTime();
		  this.winnow_results_asynch_by_group( $.extend([], this.results_data), searchText, regex, zregex, 0, this.searchBatch )
	  }else{
		  if( this.results_data.groupedData ){    
				 for (var g = 0, _len = this.results_data.length; g < _len; g++) {
					var group = this.results_data[g], 
					visibleInThisGroup = this.winnow_results_display_group( group.options, searchText, regex, zregex );
					results += visibleInThisGroup;
				  if( !visibleInThisGroup ) {
						 $("#" + group.dom_id).hide();
				  }else $("#" + group.dom_id).show();    		   
				 }
			}else{
				 results = this.winnow_results_display_group( this.results_data, searchText, regex, zregex );
			}
			
			if (results < 1 && searchText.length) {
			  return this.no_results(searchText);
			} else {
			  return this.winnow_results_set_highlight();
			}
	  }
    };
	
    Chosen.prototype.winnow_results_clear = function() {
	  var li, lis, _i, _len, _results;
      this.search_field.val("");
      return;
	  
      lis = this.search_results.find("li");
      _results = [];
      for (_i = 0, _len = lis.length; _i < _len; _i++) {
        li = lis[_i];
        li = $(li);
        _results.push(li.hasClass("group-result") ? li.show() : !this.is_multiple || !li.hasClass("result-selected") ? this.result_activate(li) : void 0);
      }
      return _results;
    };
    Chosen.prototype.winnow_results_set_highlight = function() {
      var do_high;
      if (!this.result_highlight) {
        do_high = this.search_results.find(".active-result:first");
        if (do_high) {
          return this.result_do_highlight(do_high);
        }
      }
    };
    Chosen.prototype.no_results = function(terms) {
      var no_results_html;
      no_results_html = $('<li class="no-results">No results match "<span></span>"</li>');
      no_results_html.find("span").first().text(terms);
      return this.search_results.append(no_results_html);
    };
    Chosen.prototype.no_results_clear = function() {
      return this.search_results.find(".no-results").remove();
    };
    Chosen.prototype.keydown_arrow = function() {
      var first_active, next_sib;
      if (!this.result_highlight) {
        first_active = this.dropdown.find("li.active-result:first"); // this.search_results.find("li.active-result").first();
        if (first_active.length) {
          this.result_do_highlight($(first_active));
        }
      } else if (this.results_showing) {
        next_sib = this.result_highlight.nextAll("li.active-result:first");
        if (next_sib) {
          this.result_do_highlight(next_sib);
        }
      }
      if (!this.results_showing) {
        return this.results_show();
      }
    };
    Chosen.prototype.keyup_arrow = function() {
      var prev_sibs;
      if (!this.results_showing && !this.is_multiple) {
        return this.results_show();
      } else if (this.result_highlight) {
        prev_sibs = this.result_highlight.prevAll("li.active-result");
        if (prev_sibs.length) {
          return this.result_do_highlight(prev_sibs.first());
        } else {
          if (this.choices > 0) {
            this.results_hide();
          }
          return this.result_clear_highlight();
        }
      }
    };
    Chosen.prototype.keydown_backstroke = function() {
      if (this.pending_backstroke) {
        this.choice_destroy(this.pending_backstroke.find("a").first());
        return this.clear_backstroke();
      } else {
        this.pending_backstroke = this.search_container.siblings("li.search-choice").last();
        return this.pending_backstroke.addClass("search-choice-focus");
      }
    };
    Chosen.prototype.clear_backstroke = function() {
      if (this.pending_backstroke) {
        this.pending_backstroke.removeClass("search-choice-focus");
      }
      return this.pending_backstroke = null;
    };
    Chosen.prototype.keyup_checker = function(evt) {
      var stroke, _ref;
      stroke = (_ref = evt.which) != null ? _ref : evt.keyCode;
      this.search_field_scale();
      switch (stroke) {
        case 8:
          if (this.is_multiple && this.backstroke_length < 1 && this.choices > 0) {
            return this.keydown_backstroke();
          } else if (!this.pending_backstroke) {
            this.result_clear_highlight();
            return this.results_search();
          }
          break;
        case 13:
          evt.preventDefault();
          if (this.results_showing) {
            return this.result_select( );
          }
          break;
        case 27:
          this.search_field.val("");
          if (this.results_showing) {
            return this.results_hide();
          }
          break;
        case 9:
        case 38:
        case 40:
        case 16:
          break;
        default:
          return this.results_search(evt);
      }
    };
    Chosen.prototype.keydown_checker = function(evt) {
      var stroke, _ref;
      stroke = (_ref = evt.which) != null ? _ref : evt.keyCode;
      this.search_field_scale();
      if (stroke !== 8 && this.pending_backstroke) {
        this.clear_backstroke();
      }
      switch (stroke) {
        case 8:
          this.backstroke_length = this.search_field.val().length;
          break;
        case 9:
          this.mouse_on_container = false;
          break;
        case 13:
          evt.preventDefault();
          break;
        case 37:
		case 38:
          evt.preventDefault();
          this.keyup_arrow();
          break;
        case 39: // right arrow
		case 40:
          this.keydown_arrow();
          break;
      }
    };
    Chosen.prototype.search_field_scale = function() {
      var dd_top, div, h, style, style_block, styles, w, _i, _len;
      if (this.is_multiple) {
        h = 0;
        w = 0;
        style_block = "position:absolute; left: -1000px; top: -1000px; display:none;";
        styles = ['font-size', 'font-style', 'font-weight', 'font-family', 'line-height', 'text-transform', 'letter-spacing'];
        for (_i = 0, _len = styles.length; _i < _len; _i++) {
          style = styles[_i];
          style_block += style + ":" + this.search_field.css(style) + ";";
        }
        div = $('<div />', {
          'style': style_block
        });
        div.text(this.search_field.val());
        $('body').append(div);
        w = div.width() + 25;
        div.remove();
        if (w > this.f_width - 10) {
          w = this.f_width - 10;
        }
        this.search_field.css({
          'width': w + 'px'
        });
        dd_top = this.container.height();
        return this.dropdown.css({
          "top": dd_top + "px"
        });
      }
    };
	Chosen.prototype.defauls = {
		active_field :false,
		mouse_on_container : false,
		results_showing: false,
		result_highlighted : null,
		result_single_selected : null,
		choices : 0,
		maxHeight: 200,
		asynchGroups:true,
		asynchSearch:true
    };
	
	
	
    return Chosen;
  })();
  get_side_border_padding = function(elmt) {
    var side_border_padding;
    return side_border_padding = elmt.outerWidth() - elmt.width();
  };
  root.get_side_border_padding = get_side_border_padding;
  SelectParser = (function() {
    function SelectParser( select ) {
      this.options_index = 0;
      this.parsed = [];
	  if( !select ) 
		 return;	  
	  this.parsed.id = select.id;
	  this.parsed.name = select.name;
	  this.parsed.title = select.title;
	  this.parsed.multiple = select.multiple;
	  this.parsed.total=0;
	  this.parsed.rendered=0;
    }
    SelectParser.prototype.add_node = function(child) {
      if (child.nodeName === "OPTGROUP") {
        return this.add_group(child);
      } else {
        return this.add_option(child);
      }
    };
    SelectParser.prototype.add_group = function(group) {
      var group_position, option, _i, _len, _ref, _results;
      group_position = this.parsed.length;
      this.parsed.push({
        array_index: group_position,
        group: true,
        label: group.label,
        children: 0,
        disabled: group.disabled
      });
      _ref = group.childNodes;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        option = _ref[_i];
        _results.push(this.add_option(option, group_position, group.disabled));
      }
      return _results;
    };
    SelectParser.prototype.add_option = function(option, group_position, group_disabled) {
      if (option.nodeName === "OPTION") {
        if (option.text !== "") {
          if (group_position != null) {
            this.parsed[group_position].children += 1;
          }
          this.parsed.push({
            array_index: this.parsed.length,
            options_index: this.options_index,
            value: option.value,
            text: option.text,
            selected: option.selected,
            disabled: group_disabled === true ? group_disabled : option.disabled,
            group_array_index: group_position
          });
        } else {
          this.parsed.push({
            array_index: this.parsed.length,
            options_index: this.options_index,
            empty: true
          });
        }
        return this.options_index += 1;
      }
    };
    return SelectParser;
  })();
  SelectParser.select_to_array = function(select) {
    var child, parser, _i, _len, _ref;
    parser = new SelectParser();
    _ref = select.childNodes;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      child = _ref[_i];
      parser.add_node(child);
    }
    return parser.parsed;
  };
    
 SelectParser.select_to_grouped_array = function(select) {
    var parser, 
		$select = $(select),
		_ref = select.childNodes,
		_len = _ref.length, 
 		parser = new SelectParser(select); 	
	
	for ( var g = 0; g < _len; g++) {
      var child = _ref[g], item = null;
      switch(child.nodeName.toLowerCase()){
  	    case "optgroup" :
		  item = {
			group_index: parser.parsed.length,
			group: true,
			type:'group',
			label: child.label,
			disabled: child.disabled,
			options: []
		  } 
		 var _options = child.childNodes,
		     options = item.options,
			 $optgroup = $(item);
		 
		 item.total = $optgroup.attr('total');
		 item.values = $optgroup.attr('values');
		 
		 for ( var o = 0, oL = _options.length; o < oL; o++) {
			parser.parsed.total++;
			var option = _options[o];
			if( option.nodeName.toLowerCase() !== "option") continue;
			options.push({
				group_index: parser.parsed.length,
				options_index: options.length,
				value: option.value,
				text: option.text,
				selected: option.selected,
				disabled: item.disabled || option.disabled,
				empty :  !option || !option.text
			  });
		  }
          if( !parser.parsed.groupedData){ parser.parsed.groupedData = true;}	  
		  break;
	   case "option" : 
	      item = {
				group_index: -1,
				options_index: parser.parsed.length,
				value: child.value,
				text: child.text,
				selected: !!child.selected,
				disabled: !!child.disabled,
				empty : !child.text
		  }
        parser.parsed.total++;
		  break;
		default: continue;
      }
      parser.parsed.push( item );	  
    }
	parser.parsed.count = $select.attr('count');
	parser.parsed.total = $select.attr('total');
	parser.parsed.values = $select.attr('values');
    return parser.parsed;
  };

  root.SelectParser = SelectParser;
}).call(this);
