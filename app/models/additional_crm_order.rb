# == Schema Information
#
# Table name: additional_crm_orders
#
#  id       :integer          not null, primary key
#  order_id :integer          not null
#  crm_key  :string           not null
#  name     :string
#

class AdditionalCrmOrder < ActiveRecord::Base

  belongs_to :order

  validates_by_schema

  scope :list, -> { order(:name) }

  def to_s
    name
  end

end
