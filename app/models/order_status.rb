# == Schema Information
#
# Table name: order_statuses
#
#  id       :integer          not null, primary key
#  name     :string(255)      not null
#  position :integer          not null
#

class OrderStatus < ActiveRecord::Base

  has_many :orders

  validates :name, :position, uniqueness: true

  scope :list, -> { order(:position) }

  def to_s
    name
  end

end
