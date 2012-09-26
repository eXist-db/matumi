
function getParameters(level) {
	var params = [];
	if (level) {
		params.push("level=" + level);
	}
    $("select").each(function() {
        var val = $(this).val();
        var name = this.name;
        if (name.length > 2 && name.substring(name.length - 2) == "[]")
            name = name.substring(0, name.length - 2);
        if (val)
            params.push(name + "=" + encodeURIComponent(val));
        else
        	params.push(name + "=");
    });
    return params.join("&");
}

function updateSelect(level, select, callback) {
    var params = getParameters(level);
    $.get("select.html", params, function(data) {
        select.empty().html(data);
        select.trigger("liszt:updated");
        if (callback)
            callback(data);
    });
}

function updateSummary() {
    var params = getParameters();
    $.get("summary.html", params, function(data) {
	    $("#summary").replaceWith(data);
    });
}

$(document).ready(function() {
    $(".chzn-select").chosen();
    
    /* Browsing page */
    $("#L1").change(function() {
    	$("#indicator").show();
        updateSelect(1, $("#L1-choose"), function(data) {
            updateSelect(2, $("#L2-choose"), function(data) {
	        	$("#indicator").hide();
            });
        });
    });
    $("#L1-choose").change(function() {
        $("#L2-choose").val("").trigger("liszt:updated");
        updateSelect(2, $("#L2-choose"));
        updateSummary();
    });
    $("#L2").change(function() {
        updateSelect(2, $("#L2-choose"));
    });
    $("#L2-choose").change(function() {
	    updateSummary();
    });
    /* End browsing page */
    
    /* Metadata page */
    $("#metadata-select").change(function() {
	    $("form").submit();
    });
    /* End browsing page */
});


$(document).ready(function(){
    $("a.scale").click(function(){
        var pageview = $(this).parents("div.pageview");
        var pageimage = pageview.find("img.facsimile");
        var closebutton = $(this).next();  
        $(this).css({
            "display": "none"
        });
        closebutton.css({
            "display": "block"
        });
        pageview.next().css({
            "clear":"none",
            "width":"100%"
        });
        pageview.css({ 
            
        }); 
        pageimage.css({
            "margin-left":"3%",
            "width":"80%",
            "height":"auto"
        });
        pageview.fadeIn("slow");
    });
    $("a.close").click(function(){
        var pageview = $(this).parents("div.pageview");
        var pageimage = pageview.find("img.facsimile");
        var scalebutton = $(this).prev();
        $(this).css({
            "display":"none"
        });
        scalebutton.css({
            "display":"block"
        });
        pageview.next().css({
            "clear":"none"
        });
        pageview.css({
            
        });
        pageimage.css({
            "margin-left":"0",
            "height":"84px",
            "width":"auto"
        });
    });
});


/* Kaja: open and close analysis that comes with an entry  */
$(document).ready(function(){
    $("a.viewana").click(function(){
        var anatd = $(this).parents("td.anatd");
        var anaarticle = anatd.find("div.anaarticle");
        var closebutton = $(this).next();  
        $(this).css({
            "display": "none"
        });
        closebutton.css({
            "display": "block"
        });
        anatd.next().css({
            "clear":"none"
        });
        anaarticle.css({
            "display":"block"
        });
        anatd.fadeIn("slow");
    });
    $("a.closeana").click(function(){
        var anatd = $(this).parents("td.anatd");
        var anaarticle = anatd.find("div.anaarticle");
        var viewbutton = $(this).prev();
        $(this).css({
            "display":"none"
        });
        viewbutton.css({
            "display":"block"
        });
        anatd.next().css({
            "clear":"none"
        });
        anaarticle.css({
            "display":"none"
        });
    });
});

