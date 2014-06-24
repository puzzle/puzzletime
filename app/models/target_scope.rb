# == Schema Information
#
# Table name: target_scopes
#
#  id    :integer          not null, primary key
#  label :string(255)      not null
#

class TargetScope < ActiveRecord::Base

  has_many :order_targets

  scope :list, -> { order(:name) }

  validates :name, uniqueness: true

  # TODO callbacks after create and destroy to update all order targets

  def to_s
    name
  end

end
