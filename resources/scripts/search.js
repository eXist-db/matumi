$(document).ready(function() {
    $(".facet").change(function () {
        $("#search-form").submit();
    });
    $("#clear-facets").click(function (ev) {
        $(".facet").find("input").each(function () {
            this.checked = false;
        });
    });
    resize();
});

function resize() {
    var nh = $(window).height() - $("#facets .facet-list").offset().top;
    $("#facets .facet-list").height(nh - 40);
}