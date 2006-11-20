// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function switchvisibility() {

    var type = document.getElementById("report_type").value;
    
    switch(type) {
     case "start_stop_day":
    	document.getElementById("worktime_hours").disabled = true;
    	document.getElementById("worktime_from_start_time_hour").disabled = false;
    	document.getElementById("worktime_from_start_time_minute").disabled = false;
    	document.getElementById("worktime_to_end_time_hour").disabled = false;
    	document.getElementById("worktime_to_end_time_minute").disabled = false;
    	break;
     
     default:
    	document.getElementById("worktime_from_start_time_hour").disabled = true;
    	document.getElementById("worktime_from_start_time_minute").disabled = true;
    	document.getElementById("worktime_to_end_time_hour").disabled = true;
    	document.getElementById("worktime_to_end_time_minute").disabled = true;
    	document.getElementById("worktime_hours").disabled = false;
    	break;
    }
}
