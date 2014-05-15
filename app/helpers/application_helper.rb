# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

# Methods added to this helper will be available to all templates in the application.

module ApplicationHelper

  # round time function.
  def format_hour(hour)
    # number_with_precision is not that performant
    number = (Float(hour) * (100)).round.to_f / 100
    number = '%01.2f' % number
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

  def format_percent(value)
    (value == value.to_i ? value.to_i.to_s : value.to_s) + ' %'
  end

  def evaluation_detail_params
    { evaluation: params[:evaluation],
      category_id: params[:category_id],
      division_id: params[:division_id],
      start_date: params[:start_date],
      end_date: params[:end_date],
      page: params[:page] }
  end

  def date_calendar_field(object, method, options = {})
    generic_calendar_field object, method, DATE_FORMAT, options
  end

  def week_calendar_field(object, method, title, update = false, default = Date.today)
    # TODO code updatePlanning to jquery
    # TODO handle week format
    cal_options = { onUpdate: :updatePlanning } if update
    generic_calendar_field object, method, WEEK_FORMAT #, update && :updatePlanning, default
  end

  def generic_calendar_field(object, method, date_format, html_options = {})
    date = date_value(object, method, html_options[:value])
    html_options[:size] = 15
    html_options[:class] = 'date'
    html_options[:value] = date ? date.strftime(date_format) : ''
    html_options[:data] ||= {}
    html_options[:data][:format] = date_format.gsub('%', '')

    text_field(object, method, html_options) +
    content_tag(:span, image_tag('calendar.gif',
                       title: 'Kalender anzeigen',
                       size: '15x15',
                       class: 'calendar'))
  end

  # TODO: remove this method
  def renderGenericPartial(options)
    #if template = options[:partial]
    #  if templateAbsent? template, controller.class.controller_path
    #    return if templateAbsent? template, genericPath
    #    options[:partial] = "#{genericPath}/#{template}"
    #  end
    #end
    render options
  end

  def genericPath
    '.'
  end

  private

  def date_value(object_name, method_name, default = Date.today)
    if object = instance_variable_get("@#{object_name}")
      if  date = object.send(method_name)
        return date
      end
    end
    default
  end

  def templateAbsent?(template, view)
    !File.exist?(File.join(File.dirname(__FILE__), "../views/#{view}/_#{template}.html.haml"))
  end

end
