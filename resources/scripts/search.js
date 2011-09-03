head.ready(function() {
    $(".facet").change(function () {
        $("#search-form").submit();
    });
    $(".facet li", '#facets').hover(
			function () {
				$(".facet-links", this).show();
			},
			function () {
				$(".facet-links", this).hide();
			}
	);
    $("#clear-facets").click(function (ev) {
        $(".facet").find("input").each(function () {
            this.checked = false;
        });
    });
    resize();
});

function resize() {
    var $facets =  $("#facets .facet-list");
    if( $facets.length ){
       var nh = $(window).height() - $facets.offset().top;
       $facets.height(nh - 40);
    }    
}