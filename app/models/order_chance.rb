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

class OrderChance < OrderUncertainty

  private

  def update_major_order_value
    order.update!(major_chance_value: major_order_value)
  end

  def major_order_value
    order.order_chances
         .where(type: OrderChance.sti_name)
         .pluck('MAX(probability * impact)')
         .first
  end

end
