# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

# Methods added to this helper will be available to all templates in the application.

module ApplicationHelper

  include CalendarHelper
  
  # round time function.
  def round(hour)
    "%.2f" % hour.to_f
  end
  
  # Change english datelayout to german one.
  def format_date(date)
    date.strftime("%a, %d.%m.%Y")
  end  
  
  def evaluation_detail_params
    { :evaluation => params[:evaluation],
      :category_id => params[:category_id],
      :division_id => params[:division_id],
      :page => params[:page] }
  end
  
  def date_calendar_field(object, method, title)
    calendar_field object, method,
    	{ :field_title => title,
    	  :button_image => 'calendar.gif',
    	  :button_title => 'Kalender anzeigen',
    	  :size => '15',
    	  :value => date_value(object, method).strftime(DATE_FORMAT)},
    	{ :firstDay => 1,
    	  :step => 1,
    	  :ifFormat => DATE_FORMAT,
    	  :daFormat => DATE_FORMAT,
    	  :range => [2006,2100],
    	  :showOthers => true,
    	  :cache => true }
  end
  
private  
  
  def date_value(object_name, method_name)
    if object = self.instance_variable_get("@#{object_name}")
      if date = object.send(method_name)
        return date
      end  
    end
    Date.today
  end
   
end
