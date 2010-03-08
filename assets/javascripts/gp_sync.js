/*function log_message(msg) {
	var console = window['console'];
	if (console && console.log) {
	  console.log(msg);
	}
}*/
function check_all() {
	check_boxes($("sync_form"), true);
}

function uncheck_all() {
	check_boxes($("sync_form"), false);
}

function toggle_subtasks(element) {
	check_boxes(element.parentNode, element.checked);
}

function check_boxes(element, enablement) {
	element.getElementsBySelector("li input").each(function(e){ if(e.type == "checkbox") e.checked = enablement; });
}