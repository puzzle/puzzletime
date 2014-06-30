# encoding: utf-8

# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

# Methods added to this helper will be available to all templates in the application.

module CalendarHelper

  def week_calendar_field(object, method, options = {})
    generic_calendar_field object, method, :week, options
  end

  def generic_calendar_field(object, method, date_format, html_options = {})
    date = date_value(object, method, html_options[:value])
    html_options[:size] = 15
    html_options[:class] = 'date'
    html_options[:value] = date ? I18n.l(date, format: date_format) : ''
    html_options[:data] ||= {}
    html_options[:data][:format] = date_format

    text_field(object, method, html_options) +
    icon(:calendar)
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

end
