# encoding: utf-8

# == Schema Information
#
# Table name: order_kinds
#
#  id   :integer          not null, primary key
#  name :string(255)      not null
#

class OrderKind < ActiveRecord::Base
  has_many :orders, foreign_key: :kind_id

  validates_by_schema
  validates :name, uniqueness: true

  protect_if :orders, 'Der Eintrag kann nicht gelöscht werden, da ihm noch Aufträge zugeordnet sind'

  scope :list, -> { order(:name) }

  def to_s
    name
  end
end
