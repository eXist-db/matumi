$('#L1').live('change', function(event){
     var $this = $(e.target),
         value = $this.val(),
         $L2 = $('#L2'),
         $L3 = $('#L3');
     
     $('#browseForm option:disabled').removeAttr('disabled');
     $('#L2 option[value=' + value + '], #L3 option[value=' + value + '] ').attr('disabled', true );
     if( $L2.val() == value ) {  $L2.val( $L2.find('option:enabled')[0].attr('value')); }
     $('option[value=' + $L2.val() + ']', $L3 ).attr('disabled', true );
});

$('#L2').live('change', function(event){
     var $L2 = $(e.target),
         $L1 = $('#L1'),
         $L3 = $('#L3');
     
     $('option:disabled', $L3).removeAttr('disabled');
     $('option[value=' + $L1.val() + '], option[value=' + $L2.val() + '] ').attr('disabled', true );
});