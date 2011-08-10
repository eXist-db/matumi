function browse_Set_L3( event, $L1, $L2, $L3){
    var $autoUpdate = $('#autoUpdate');
    $L1 = $L1 || $('#L1');
    $L2 = $L2 || $('#L2');    
    $L3 = $L3 || $('#L3');    
    $('option:disabled', $L3).removeAttr('disabled').show();
    $('option[value=' + $L1.val() + '], option[value=' + $L2.val() + '] ', $L3).attr('disabled', 'true' ).hide();
    $L3.val( $L3.find('option:enabled').eq(0).attr('value')); 
    $('#browseForm').submit();
/*    
    if( $autoUpdate.length == 0 || $autoUpdate.is(':checked')) {   
       $('#browseForm').submit();
    }
*/    
}

function fetchAJAXfragment( pos, that ){
        var $this = $(that).removeClass('');
        //var URL = $this.attr('url') +'?' + $("#browseForm").serialize();
        var section = $this.attr('section')?  { section: $this.attr('section') }: {dummy:'yes'};
        $this.load( $this.attr('url'), section, function(response, status, xhr) {
            var newDom = $this.find(' > *').remove();
            $this.replaceWith( newDom );
            if( newDom.hasClass('chzn-select')) { newDom.chosen() };
            //$this.removeClass('loading-grey ajax-loaded-combo');
             $('.ajax-loaded', newDom ).each( fetchAJAXfragment);            
        });
};

$(document).ready(function() {
    $('#L1').live('change', function(event){
         var $L1 = $(event.target),
             $L2 = $('#L2'),
             $L3 = $('#L3'),
             v1 = $L1.val(),
             v2 = $L2.val(),
             v3 = $L3.val();
         
         $('#browseForm option:disabled').removeAttr('disabled').show();
         $('#L2 option[value=' + v1 + ']').attr('disabled', 'true' ).hide();
         if( v2 == v1 ) { 
             $L2.val( $L2.find('option:enabled').eq(0).attr('value')); 
         }
         browse_Set_L3(null, $L1, $L2, $L3 );
    });
    
    $('#L2').live('change', browse_Set_L3 );
    $(".chzn-select").chosen();
    
     $('.ajax-loaded').each( fetchAJAXfragment);
    
    /*
    $('.ajax-loaded').each( function(pos, item ){
        
        var $this = $(this).removeClass('');
        //var URL = $this.attr('url') +'?' + $("#browseForm").serialize();
        var section = $this.attr('section')?  { section: $this.attr('section') }: {dummy:'yes'};
        $this.load( $this.attr('url'), section, function(response, status, xhr) {
            var newDom = $this.find(' > *').remove();
            $this.replaceWith( newDom );
            if( newDom.hasClass('chzn-select')) { newDom.chosen() };
            //$this.removeClass('loading-grey ajax-loaded-combo');
                        
        });
    })
    */
    
    $("a.combo-reset").live('click', function(evnt){
        $('#'+ $(this).attr('combo2reset') +  '_chzn a.search-choice-close').trigger('click');
        $('#'+ $(this).attr('combo2reset') +  ' option:selected').removeAttr('selected');
        
    });
    
});

