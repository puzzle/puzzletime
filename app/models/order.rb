# encoding: utf-8
# == Schema Information
#
# Table name: orders
#
#  id                 :integer          not null, primary key
#  path_item_id       :integer          not null
#  kind_id            :integer
#  responsible_id     :integer
#  status_id          :integer
#  department_id      :integer
#  contract_id        :integer
#  billing_address_id :integer
#  created_at         :datetime
#  updated_at         :datetime
#

class Order < ActiveRecord::Base

  belongs_to :path_item
  belongs_to :kind, class_name: 'OrderKind'
  belongs_to :status, class_name: 'OrderStatus'
  belongs_to :responsible, class_name: 'Employee'
  belongs_to :department
  belongs_to :contract
  belongs_to :billing_address

  # TODO
  # has_one :client, through: :path_item

  has_many :comments, class_name: 'OrderComment'
  has_many :targets, class_name: 'OrderTarget'

  has_and_belongs_to_many :employees
  has_and_belongs_to_many :contacts

  validates :kind_id, :responsible_id, :status_id, :department_id, presence: true

  # TODO: validate only one order per path_items path_ids
  # TODO: after create callback to initialize order targets

  scope :list, -> do
    includes(:path_item).
    references(:path_item).
    order(path_item: :shortname)
  end

  def to_s
    path_item.to_s
  end

end
