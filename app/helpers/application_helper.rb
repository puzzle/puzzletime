# Methods added to this helper will be available to all templates in the application.

module ApplicationHelper

include ActionView::Helpers::DateHelper

 def select_worktime_html(id, type, options, prefix = nil, include_blank = false, discard_type = false, disabled = false)
    select_worktime_html  = %(<select id="#{id}" name="#{prefix || DEFAULT_PREFIX})
    select_worktime_html << "[#{type}]" unless discard_type
    select_worktime_html << %(")
    select_worktime_html << %( disabled="disabled") if disabled
    select_worktime_html << %(>)
    select_worktime_html << %(<option value=""></option>) 
    if include_blank
      select_worktime_html << options.to_s
      select_worktime_html << "</select>"
    end
  end
end
