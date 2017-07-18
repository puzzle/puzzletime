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

class OrderUncertainty < ActiveRecord::Base

  belongs_to :order

  enum probability: {
    improbable: 1,
    low: 2,
    medium: 3,
    high: 4
  }, _suffix: true

  enum impact: {
    none: 1,
    low: 2,
    medium: 3,
    high: 4
  }, _suffix: true

  after_save :update_major_order_value
  after_destroy :update_major_order_value

  scope :list, -> { order(:order_id, 'probability * impact DESC') }

  class << self
    def risk(value)
      return unless value.present?

      if value < 3
        :low
      elsif value < 8
        :medium
      else
        :high
      end
    end
  end

  def to_s
    name
  end

  def risk_value
    probability_value * impact_value
  end

  def risk
    OrderUncertainty.risk(risk_value)
  end

  def probability_value
    OrderUncertainty.probabilities[probability]
  end

  def impact_value
    OrderUncertainty.impacts[impact]
  end

  protected

  def update_major_order_value
    raise # implement in child class
  end

end
