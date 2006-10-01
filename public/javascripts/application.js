// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function report_type()
{
  var chosen; 
 
  chosen = f.report_type.options[f.report_type.selectedIndex].value;
  
  if (chosen == start_stop_day){
	document.createtime.worktime[hours].disabled;
	}
}
