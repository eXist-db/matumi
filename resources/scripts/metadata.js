function browse_Set_L3( event, $L1, $L2, $L3){
    var $autoUpdate = $('#autoUpdate');
    $L1 = $L1 || $('#L1');
    $L2 = $L2 || $('#L2');    
    $L3 = $L3 || $('#L3');    
    $('option:disabled', $L3).removeAttr('disabled').show();
    $('option[value=' + $L1.val() + '], option[value=' + $L2.val() + '] ', $L3).attr('disabled', 'true' ).hide();
    $L3.val( $L3.find('option:enabled').eq(0).attr('value')); 
/*    
    if( $autoUpdate.length == 0 || $autoUpdate.is(':checked')) {   
       
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
    $('#books').live('change', function(event){
       $('#browseForm').submit();
    });
});

