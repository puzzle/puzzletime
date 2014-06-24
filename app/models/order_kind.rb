# == Schema Information
#
# Table name: order_kinds
#
#  id   :integer          not null, primary key
#  name :string(255)      not null
#

class OrderKind < ActiveRecord::Base

  has_many :orders

  validates :name, uniqueness: true

  scope :list, -> { order(:name) }

  def to_s
    name
  end

end
