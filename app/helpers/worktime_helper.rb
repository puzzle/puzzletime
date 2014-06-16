# encoding: utf-8

module WorktimeHelper

  def select_report_type(auto_start_stop_type = false)
    options = ReportType::INSTANCES
    options = [AutoStartType::INSTANCE] + options if auto_start_stop_type
    select 'worktime',
           'report_type',
           options.collect { |type| [type.name, type.key] },
           { selected: @worktime.report_type.key },
           onchange: 'App.switchTimeFieldsVisibility();'
  end

  def account_options
    options_for_select = @accounts.inject([]) do |options, element|
      value = element.id
      selected_attribute = ' selected="selected"' if @worktime.account_id == value
      title_attribute = " title=\"#{element.tooltip}\"" if element.tooltip.present?
      options << %(<option value="#{h(value)}"#{selected_attribute}#{title_attribute}>#{h(element.label_verbose)}</option>)
    end

    options_for_select.join("\n").html_safe
  end

end
