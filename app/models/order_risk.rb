# == Schema Information
#
# Table name: order_uncertainties
#
#  id          :integer          not null, primary key
#  order_id    :integer          not null
#  type        :string           not null
#  name        :string           not null
#  probability :integer          default("improbable"), not null
#  impact      :integer          default("none"), not null
#  measure     :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class OrderRisk < OrderUncertainty

  private

  def update_major_order_value
    order.update!(major_risk_value: major_order_value)
  end

  def major_order_value
    order.risks
         .pluck('MAX(probability * impact)')
         .first
  end

end
