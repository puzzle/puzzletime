# encoding: utf-8
# == Schema Information
#
# Table name: order_statuses
#
#  id       :integer          not null, primary key
#  name     :string(255)      not null
#  style    :string(255)
#  closed   :boolean          default(FALSE), not null
#  position :integer          not null
#

class OrderStatus < ActiveRecord::Base
  STYLES = %w(default success info warning danger)

  include Closable

  has_many :orders, foreign_key: :status_id

  validates_by_schema
  validates :name, :position, uniqueness: true
  validates :style, inclusion: STYLES

  protect_if :orders, 'Der Eintrag kann nicht gelöscht werden, da ihm noch Aufträge zugeordnet sind'

  scope :list, -> { order(:position) }


  def to_s
    name
  end

  def propagate_closed!
    orders.includes(:status).find_each(&:propagate_closed!)
  end
end
