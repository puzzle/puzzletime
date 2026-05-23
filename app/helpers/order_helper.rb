# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module OrderHelper
  def order_team_enumeration(order)
    list = order.team_members.to_a

    if list.size > 2
      linked_employee_enumeration(list.take(2)) + ', &hellip;'.html_safe
    else
      linked_employee_enumeration(list)
    end
  end

  def linked_employee_enumeration(employees)
    safe_join(employees, ', ') { |e| link_to(e, e) }
  end

  def order_contacts_enumeration(order)
    list = order.contacts.to_a
    contacts = safe_join(list.take(2), ', ')
    contacts << ', &hellip;'.html_safe if list.size > 2
    contacts
  end

  def order_target_rating_icon(rating, options = {})
    options[:style] ||= 'font-size: 20px;'
    add_css_class(options, rating)
    picon(order_target_icon_key[rating], options)
  end

  def order_target_icon(target)
    return unless target

    order_target_rating_icon(
      target.rating,
      title: target.comment? ? simple_format(target.comment).gsub('"', '&quot;') : nil,
      data: { toggle: :tooltip }
    )
  end

  def order_target_icon_key
    @order_target_icon_key ||= {
      'green' => 'disk',
      'orange' => 'triangle',
      'red' => 'square'
    }
  end

  def format_order_status_style(status)
    content_tag(:span, status.name, class: "label label-#{status.style}")
  end

  def format_target_scope_icon(scope)
    icon(scope.icon)
  end

  def format_order_crm_key(order)
    crm_order_link(order)
  end

  def format_order_crm_key_with_name(order)
    crm_order_link(order, order.crm_key_with_label)
  end

  def format_order_billability(value)
    content_tag(:span, f(value), class: order_report_billability_class(value))
  end

  def format_order_average_rate(value)
    content_tag(:span, f(value), class: order_report_average_rate_class(value))
  end

  def format_order_additional_crm_orders(order)
    names = order.additional_crm_orders.map do |crm_order|
      crm_order_link(crm_order, crm_order.crm_key_with_label)
    end
    simple_list(names)
  end

  def format_major_chance(order)
    return if order.nil?

    content_tag(:span, safe_join(risk_icons(order.major_chance, OrderChance.sti_name)),
                style: 'font-size: 20px;',
                title: uncertainties_tooltip(order, OrderChance.sti_name),
                data: { toggle: :tooltip })
  end

  def format_major_risk(order)
    return if order.nil?

    content_tag(:span, safe_join(risk_icons(order.major_risk, OrderRisk.sti_name)),
                style: 'font-size: 20px;',
                title: uncertainties_tooltip(order, OrderRisk.sti_name),
                data: { toggle: :tooltip })
  end

  def glyphicons
    %w[asterisk plus euro minus cloud envelope pencil glass music search heart star star-empty
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
       tree-conifer tree-deciduous]
  end

  def choosable_order_options
    managed_orders =
      current_user
      .managed_orders
      .where.not(id: @order.id) # Selectize does not play well with dupes
      .where(work_items: { closed: false })
      .list
      .minimal

    selected_option = order_option(@order, true)
    managed_options = safe_join(managed_orders) { order_option(_1) }

    managed_options + selected_option
  end

  def order_option(order, selected = false)
    return unless order

    json = { id: order.id,
             name: order.name,
             path_shortnames: order.path_shortnames }
    content_tag(:option,
                order.label_verbose,
                value: order.id,
                selected:,
                data: { data: json.to_json })
  end

  def order_report_billability_class(value)
    config = Settings.reports.orders.billability
    if value >= config.green
      'green'
    elsif value >= config.orange
      'orange'
    else
      'red'
    end
  end

  def order_report_average_rate_class(value)
    config = Settings.reports.orders.average_rate
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

  def uncertainties_tooltip(order, uncertainty_type)
    uncertainties = uncertainties_grouped_by_risk(order, uncertainty_type)
    %i[high medium low]
      .select { |risk| uncertainties.key?(risk) }
      .reduce('') do |result, risk|
        title = t("activerecord.attributes.order_uncertainty/risks.#{risk}")
        names = uncertainties[risk].map { |u| "<li>#{h(u.name)}</li>" }.join
        result + "<h5>#{title}:</h5><ul class=\"list-unstyled\">#{names}</ul>"
      end
  end

  def uncertainties_grouped_by_risk(order, uncertainty_type)
    order.order_uncertainties
         .to_a
         .select { |u| u.type == uncertainty_type }
         .sort_by(&:risk_value)
         .group_by(&:risk)
  end
end
