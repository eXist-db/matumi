$(document).ready(function() {
    $(".facet").change(function () {
        $("#search-form").submit();
    });
    resize();
});

function resize() {
    var nh = $(window).height() - $("#facets").offset().top;
    $("#facets").height(nh - 20);
    var rh = $(".results").height();
    if (rh < $(window).height()) {
        $(".results").height(nh);
    }
}