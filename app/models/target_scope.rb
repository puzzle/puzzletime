# encoding: utf-8
# == Schema Information
#
# Table name: target_scopes
#
#  id       :integer          not null, primary key
#  name     :string(255)      not null
#  icon     :string(255)
#  position :integer          not null
#


class TargetScope < ActiveRecord::Base

  has_many :order_targets, dependent: :destroy

  validates :name, :position, :icon, presence: true, uniqueness: true

  after_create :create_order_targets

  scope :list, -> { order(:position) }

  def to_s
    name
  end

  private

  def create_order_targets
    Order.find_each do |o|
      o.targets.create!(target_scope: self, rating: OrderTarget::RATINGS.first)
    end
  end

end
