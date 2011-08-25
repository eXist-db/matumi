function fetchAJAXfragment( pos, that ){
        var $this = $(that).removeClass('');
        //var URL = $this.attr('url') +'?' + $("#browseForm").serialize();
        var section = $this.attr('section')?  { section: $this.attr('section') }: {dummy:'yes'};
        $this.load( $this.attr('url'), section, function(response, status, xhr) {
            var newDom = $this.find(' > *').remove();
            if($this.attr('copyURL') == 'yes') 
                 newDom.attr('url', $this.attr('url'));
            $this.replaceWith( newDom );
            if( newDom.hasClass('chzn-select')) { newDom.chosen() };
            //$this.removeClass('loading-grey ajax-loaded-combo');
             $('.ajax-loaded', newDom ).each( fetchAJAXfragment);            
        });
};

function disableSinleOption( $t, value ){
    var current = $t.val();    
    $t.find( 'option[value=' + value + ']').attr('disabled', 'true' ).hide();      
    if( current == value ){         
       $t.val( $t.find('option:enabled').eq(0).attr('value')); 
    }

};

function disableLeftOptions( $leftCombos, $combosToDisable  ){   
   var $select = $combosToDisable.eq(0);
   $select.find('option:disabled').removeAttr('disabled').show();
   for( var i = 0; i< $leftCombos.length; i++){      
      disableSinleOption($select,$leftCombos.eq(i).val());
   }
   if( $combosToDisable.length > 1){
      disableLeftOptions( $leftCombos.add($select), $combosToDisable.slice(1) );
   }
};





$(document).ready(function() {
    $('#L1').live('change', function(event){
         disableLeftOptions( $(event.target), $('#L2, #L3, #L4'));
         $('#browseForm').submit();
    });
     $('#L2').live('change', function(event){
          disableLeftOptions( $('#L1, #L2'), $('#L3, #L4')); 
          $('#browseForm').submit();          
     });
     $('#L3').live('change', function(event){
          disableLeftOptions( $('#L1, #L2, #L3'), $('#L4')); 
          $('#browseForm').submit();          
     });
    
     $("a.combo-reset").live('click', function(evnt){
        $('#'+ $(this).attr('combo2reset') +  '_chzn a.search-choice-close').trigger('click');
        $('#'+ $(this).attr('combo2reset') +  ' option:selected').removeAttr('selected');  
         $('#browseForm').submit(); 
    });    
    
    
    $('.cat-toggle.collapsed').live('click', function(){
        $(this).closest('.cat-container').add( $(this)).addClass('expanded').removeClass('collapsed');
    });  
    $('.cat-toggle.expanded').live('click', function(){
        $(this).closest('.cat-container').add( $(this)).addClass('collapsed').removeClass('expanded');
    });  
    
    
    $(".chzn-select").chosen();    
    $('.ajax-loaded').each( fetchAJAXfragment); 
    
	$('#bottom').scrollExtend({	
			'newElementClass': 'list_item more_content',		
			'target': '#dummy-cont',
			'url': function($dom, options ){
			    var $target = $('#entryGrid'), //$(options.target),
			        page = ( $dom.data('page') || 1) + 1,
			        url  = $target.attr('url'),
			        lastPage = $dom.data('noMoreData' ) || $target.attr('noMoreData') === 'yes';
			    
			    if( !$target.length ){
			       $('#bottom').scrollExtend( 'disable');
			       return null;
			    }else if( lastPage ) {
			        $dom.data('noMoreData', true );	
			        return null;
			    }else{
    		        $dom.data('page', page );			    
    			    return url + '&page=' + page;
    		    }
			}, 
			'onSuccess': function ( data, target, $dom ){
			   var tbl =  $('#entryGrid'),
			       $data =  $(data);
			   
			   if( $data.attr('noMoreData') ){
			       $dom.data('noMoreData', true );
			       // return false;
			   }		   
			   target.find('tbody').appendTo(tbl);
			   target.empty();
			   $('.ajax-loaded', tbl ).each( fetchAJAXfragment);   
			   return false;			  
			}
	});
		    
});

