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

  has_many :order_targets

  validates :name, :position, :icon, presence: true, uniqueness: true

  protect_if :order_targets, 'Der Eintrag kann nicht gelöscht werden, da ihm noch Ziele zugeordnet sind'

  scope :list, -> { order(:position) }

  def to_s
    name
  end

end
