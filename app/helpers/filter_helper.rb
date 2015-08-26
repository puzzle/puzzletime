module FilterHelper

  def predefined_period_options
    [IdValue.new('0m', 'Dieser Monat'),
     IdValue.new('-1m', 'Letzter Monat'),
     IdValue.new('-2m', 'Vorletzter Monat')]
  end

  def yes_no_options
    [IdValue.new(true, 'ja'),
     IdValue.new(false, 'nein')]
  end

  def direct_filter(name, label)
    html = ''.html_safe
    html += label_tag(name, label, class: 'control-label') + ' &nbsp; '.html_safe if label
    html += yield
    content_tag(:div, html, class: 'form-group') +
    ' &nbsp; &nbsp; '.html_safe
  end

  def direct_filter_date(name, label, date)
    direct_filter(name, label) do
      content_tag(:div, class: 'input-group') do
        text_field_tag(name,
                       date && I18n.l(date),
                       size: 9,
                       class: 'form-control date',
                       data: { submit: true }) +
        content_tag(:div, icon(:calendar), class: 'input-group-addon')
      end
    end
  end

  def direct_filter_select(name, label, list, prompt = 'Alle', value_method = :id, text_method = :to_s)
    direct_filter(name, label) do
      select_tag(name,
                 options_from_collection_for_select(list, value_method, text_method, params[name]),
                 prompt: prompt,
                 class: 'form-control',
                 data: { submit: true })
    end
  end

end
