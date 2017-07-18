module OrderUncertaintyHelper
  def format_probability(value)
    t("activerecord.attributes.order_uncertainty.probabilities.#{value.probability}")
  end

  def format_impact(value)
    t("activerecord.attributes.order_uncertainty.impacts.#{value.impact}")
  end

  def format_risk(value)
    risk_icon = value.is_a?(OrderRisk) ? 'cloud' : 'clover'
    risk_class = "order-#{value.is_a?(OrderRisk) ? 'risk' : 'chance'}-icon #{value.risk}"
    picon(risk_icon, title: t("activerecord.attributes.order_uncertainty.risks.#{value.risk}"),
                     class: risk_class)
  end

  def format_measure(value)
    auto_link(value.measure)
  end
end
