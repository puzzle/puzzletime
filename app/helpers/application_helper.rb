# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

# Methods added to this helper will be available to all templates in the application.

module ApplicationHelper
  
  # round time function.
  def format_hour(hour)
    # number_with_precision is not that performant
    number = (Float(hour) * (100)).round.to_f / 100
    number = "%01.2f" % number
    parts = number.split('.')
    parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1'")
    parts.join('.')
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
  
  def date_calendar_field(object, method, title, update = false, default = Date.today)
    cal_options = {:onUpdate => :workDateChanged} if update    
    generic_calendar_field object, method, title, DATE_FORMAT, cal_options, default
  end

  def week_calendar_field(object, method, title, update = false, default = Date.today)
    cal_options = {:onUpdate => :updatePlanning} if update    
    generic_calendar_field object, method, title, WEEK_FORMAT, cal_options, default
  end
  
  def generic_calendar_field(object, method, title, date_format, cal_options, default = Date.today)
    cal_options ||= {}
    @has_calendar = true    # used to include calendar js/css
    date = date_value(object, method, default)
    html_options = { :field_title => title,
        :button_image => 'calendar.gif',
        :button_title => 'Kalender anzeigen',
        :size => '15',
        :value => date ? date.strftime(date_format) : ""}
    cal_options.merge!({
        :firstDay => 1,
        :step => 1,
        :ifFormat => date_format,
        :daFormat => date_format,
        :range => [2006,2100],
        :showOthers => true,
        :cache => true })
    calendar_field object, method, html_options, cal_options
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
  
  def date_value(object_name, method_name, default = Date.today)
    if object = self.instance_variable_get("@#{object_name}")
      if  date = object.send(method_name)
        return date
      end      
    end
    default
  end
  
  def templateAbsent?(template,view)
    ! File.exist?(File.join(File.dirname(__FILE__), "../views/#{view}/_#{template}.rhtml"))
  end  
   
end
