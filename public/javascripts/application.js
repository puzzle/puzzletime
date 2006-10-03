// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function switchvisibility(){

var type = document.getElementById("report_type").value;

switch(type){
 case "start_stop_day": 
	document.getElementById("worktime_hours").disabled = true;
 
 case "absolute_day":
	document.getElementById("worktime_from_start_time").disabled = true;
	document.getElementById("worktime_to_end_time").disabled = true;
	document.getElementById("worktime_hours").disabled = false;

 case "worktime_week":
	document.getElementById("worktime_from_start_time").disabled = true;
	document.getElementById("worktime_to_end_time").disabled = true;
 
 case "worktime_month":
	document.getElementById("worktime_from_start_time").disabled = true;
	document.getElementById("worktime_to_end_time").disabled = true;
 }
}
