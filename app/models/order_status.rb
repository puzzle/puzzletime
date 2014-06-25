# encoding: utf-8

# == Schema Information
#
# Table name: order_statuses
#
#  id       :integer          not null, primary key
#  name     :string(255)      not null
#  position :integer          not null
#

class OrderStatus < ActiveRecord::Base

  has_many :orders, foreign_key: :status_id

  validates :name, :position, uniqueness: true

  protect_if :orders, 'Der Eintrag kann nicht gelöscht werden, da ihm noch Aufträge zugeordnet sind'

  scope :list, -> { order(:position) }

  def to_s
    name
  end

end
