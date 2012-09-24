
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