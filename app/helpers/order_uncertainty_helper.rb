# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


module OrderUncertaintyHelper

  def format_probability(value)
    t("activerecord.attributes.order_uncertainty/probabilities.#{value.probability}")
  end

  def format_impact(value)
    t("activerecord.attributes.order_uncertainty/impacts.#{value.impact}")
  end

  def format_risk(value)
    content_tag(:span, safe_join(risk_icons(value.risk, value.type)),
                title: t("activerecord.attributes.order_uncertainty/risks.#{value.risk}"),
                data: { toggle: :tooltip })
  end

  def format_measure(value)
    auto_link(value.measure)
  end

  def risk_icons(risk, type)
    count = risk_icon_count(risk)
    return [] if count.zero?

    icon_name = type == OrderRisk.sti_name ? 'cloud' : 'clover'
    (1..3).map do |i|
      icon_class = "order-#{type == OrderRisk.sti_name ? 'risk' : 'chance'}-icon"
      icon_class += ' inactive' if i > count
      picon(icon_name, class: icon_class)
    end
  end

  def risk_icon_count(risk)
    case risk
    when :high then 3
    when :medium then 2
    when :low then 1
    else 0
    end
  end
end
