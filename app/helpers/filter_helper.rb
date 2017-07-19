# encoding: utf-8

module FilterHelper
  def predefined_past_period_options
    [IdValue.new('0m', 'Dieser Monat'),
     IdValue.new('-1m', 'Letzter Monat'),
     IdValue.new('-2m', 'Vorletzter Monat')]
  end

  def predefined_past_quarter_period_options
    [IdValue.new('-1q', 'Letztes Quartal'),
     IdValue.new('-2q', 'Vorletztes Quartal')]
  end

  def predefined_future_period_options
    [IdValue.new('3M', 'Nächste 3 Monate'),
     IdValue.new('6M', 'Nächste 6 Monate'),
     IdValue.new('9M', 'Nächste 9 Monate'),
     IdValue.new('12M', 'Nächste 12 Monate')]
  end

  def yes_no_options
    [IdValue.new(true, 'ja'),
     IdValue.new(false, 'nein')]
  end

  def order_uncertainty_options
    [IdValue.new(:low, 'gering'),
     IdValue.new(:medium, 'mittel'),
     IdValue.new(:high, 'gross')]
  end

  def direct_filter(name, label, &block)
    html = ''.html_safe
    html += label_tag(name, label, class: 'control-label') + ' &nbsp; '.html_safe if label
    html += capture(&block)
    content_tag(:div, html, class: 'form-group')
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

  def direct_filter_select(name, label, list, options = {})
    options.reverse_merge!(prompt: 'Alle', value_method: :id, text_method: :to_s, value: params[name])
    add_css_class(options, 'form-control')
    options[:data] ||= {}
    options[:data][:submit] = true
    select_options = options_from_collection_for_select(list,
                                                        options.delete(:value_method),
                                                        options.delete(:text_method),
                                                        options.delete(:value))
    direct_filter(name, label) do
      select_tag(name, select_options, options)
    end
  end
end
