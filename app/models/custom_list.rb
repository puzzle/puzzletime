# == Schema Information
#
# Table name: custom_lists
#
#  id          :integer          not null, primary key
#  name        :string           not null
#  employee_id :integer
#  item_type   :string           not null
#  item_ids    :integer          not null, is an Array
#

class CustomList < ActiveRecord::Base

  belongs_to :employee

  validates_by_schema except: :item_ids

  scope :list, -> { order(:name) }

  attr_readonly :item_type

  def to_s
    name
  end

  def items
    item_type.constantize.where(id: item_ids)
  end

end
