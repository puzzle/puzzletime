// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
function switch_half_day(day) {
	document.getElementById(day + '_am').checked = document.getElementById(day).checked
	document.getElementById(day + '_pm').checked = document.getElementById(day).checked
}
function switch_day(day){
	document.getElementById(day).checked = document.getElementById(day + '_am').checked && document.getElementById(day + '_pm').checked
}

