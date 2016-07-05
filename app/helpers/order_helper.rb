module OrderHelper
  def order_team_enumeration(order)
    list = order.team_members.to_a

    if list.size > 2
      linked_employee_enumeration(list.take(2)) + ', ...'
    else
      linked_employee_enumeration(list)
    end
  end

  def linked_employee_enumeration(employees)
    safe_join(employees, ', ') { |e| link_to(e, e) }
  end

  def order_target_rating_icon(rating, options = {})
    options[:style] ||= 'font-size: 20px;'
    add_css_class(options, rating)
    picon(order_target_icon_key(rating), options)
  end

  def order_target_icon(target)
    return unless target
    order_target_rating_icon(
      target.rating,
      title: target.comment? ? simple_format(target.comment) : nil,
      data: { toggle: :tooltip })
  end

  def order_target_icon_key(rating)
    case rating
    when 'green' then 'disk'
    when 'orange' then 'triangle'
    when 'red' then 'square'
    end
  end

  def format_order_status_style(status)
    content_tag(:span, status.name, class: "label label-#{status.style}")
  end

  def format_target_scope_icon(scope)
    icon(scope.icon)
  end

  def format_order_crm_key(order)
    link_to(order.crm_key, Crm.instance.order_url(order), target: :blank) if order.crm_key?
  end

  def format_order_billability(value)
    content_tag(:span, f(value), class: order_report_billability_class(value))
  end

  def format_order_average_rate(value)
    content_tag(:span, f(value), class: order_report_average_rate_class(value))
  end

  def format_order_completed_month_end_at(order)
    if order.completed_month_end_at
      I18n.l(order.completed_month_end_at, format: :month)
    end
  end

  def glyphicons
    %w(asterisk plus euro minus cloud envelope pencil glass music search heart star star-empty
       user film th-large th th-list ok remove zoom-in zoom-out off signal cog trash home file
       time road download-alt download upload inbox play-circle repeat refresh list-alt lock flag
       headphones volume-off volume-down volume-up qrcode barcode tag tags book bookmark print
       camera font bold italic text-height text-width align-left align-center align-right
       align-justify list indent-left indent-right facetime-video picture map-marker adjust tint
       edit share check move step-backward fast-backward backward play pause stop forward
       fast-forward step-forward eject chevron-left chevron-right plus-sign minus-sign remove-sign
       ok-sign question-sign info-sign screenshot remove-circle ok-circle ban-circle arrow-left
       arrow-right arrow-up arrow-down share-alt resize-full resize-small exclamation-sign gift
       leaf fire eye-open eye-close warning-sign plane calendar random comment magnet chevron-up
       chevron-down retweet shopping-cart folder-close folder-open resize-vertical
       resize-horizontal hdd bullhorn bell certificate thumbs-up thumbs-down hand-right hand-left
       hand-up hand-down circle-arrow-right circle-arrow-left circle-arrow-up circle-arrow-down
       globe wrench tasks filter briefcase fullscreen dashboard paperclip heart-empty link phone
       pushpin usd gbp sort sort-by-alphabet sort-by-alphabet-alt sort-by-order sort-by-order-alt
       sort-by-attributes sort-by-attributes-alt unchecked expand collapse-down collapse-up log-in
       flash log-out new-window record save open saved import export send floppy-disk floppy-saved
       floppy-remove floppy-save floppy-open credit-card transfer cutlery header compressed
       earphone phone-alt tower stats sd-video hd-video subtitles sound-stereo sound-dolby
       sound-5-1 sound-6-1 sound-7-1 copyright-mark registration-mark cloud-download cloud-upload
       tree-conifer tree-deciduous)
  end

  private

  def order_report_billability_class(value)
    config = Settings.orders.reports.billability
    if value >= config.green
      'green'
    elsif value >= config.orange
      'orange'
    else
      'red'
    end
  end

  def order_report_average_rate_class(value)
    config = Settings.orders.reports.average_rate
    if value >= config.green
      'green'
    elsif value >= config.yellow
      'yellow'
    elsif value >= config.orange
      'orange'
    else
      'red'
    end
  end

end
