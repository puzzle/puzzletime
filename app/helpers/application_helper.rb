# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

# Methods added to this helper will be available to all templates in the application.

module ApplicationHelper
  
  # round time function.
  def format_hour(hour)
    number_with_delimiter(number_with_precision(hour.to_f, 2), "'")
  end
  
  # Change english datelayout to german one.
  def format_date(date)
    date ? date.strftime(LONG_DATE_FORMAT) : ''
  end    
  
  def format_time(time)
    time ||= Time.now
    time.strftime(TIME_FORMAT)
  end
    
  def alternate_row(attrs = '')
    @row = -1 if ! defined? @row    
    @row += 1
    @row.modulo(2) == 1 ? "<tr class=\"uneven\" #{attrs}>" : "<tr #{attrs}>"
  end    
  
  def evaluation_detail_params    
    { :evaluation => params[:evaluation],
      :category_id => params[:category_id],
      :division_id => params[:division_id],
      :start_date => params[:start_date],
      :end_date => params[:end_date],
      :page => params[:page] }
  end
  
  def evaluation_overview_params(prms = {})
    prms[:evaluation] ||= params[:evaluation]
    prms[:category_id] ||= params[:category_id]
    prms
  end
  
  def date_calendar_field(object, method, title, update = false)
    @has_calendar = true    # used to include calendar js/css
    html_options = { :field_title => title,
        :button_image => 'calendar.gif',
        :button_title => 'Kalender anzeigen',
        :size => '15',
        :value => date_value(object, method).strftime(DATE_FORMAT)}
    cal_options = { :firstDay => 1,
        :step => 1,
        :ifFormat => DATE_FORMAT,
        :daFormat => DATE_FORMAT,
        :range => [2006,2100],
        :showOthers => true,
        :cache => true }    
    cal_options[:onUpdate] = :workDateChanged if update    
    calendar_field object, method, html_options, cal_options
  end
  
  def blackout_hash(hash, *keys)
    dupe = hash.dup
    dupe.each_pair do |key, value|
      if keys.include? key
        dupe[key] = '***'
      elsif value.kind_of? Hash
        dupe[key] = blackout_hash(value, *keys)
      end
    end
    dupe
  end
  
  def renderGenericPartial(options)
    if template = options[:partial]
      if templateAbsent? template, controller.class.controller_path
        return if templateAbsent? template, genericPath        
        options[:partial] = "#{genericPath}/#{template}"      
      end  
    end    
    render options  
  end
  
  def genericPath
    '.'
  end
  
private  
  
  def date_value(object_name, method_name)
    if object = self.instance_variable_get("@#{object_name}")
      if  date = object.send(method_name)
        return date
      end      
    end
    Date.today
  end
  
  def templateAbsent?(template,view)
    ! finder.file_exists? "#{view}/_#{template}.rhtml"
  end  
   
end
