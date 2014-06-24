# == Schema Information
#
# Table name: orders
#
#  id                 :integer          not null, primary key
#  budget_item_id     :integer          not null
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

  belongs_to :budget_item, class_name: 'Project'
  belongs_to :kind, class_name: 'OrderKind'
  belongs_to :status, class_name: 'OrderStatus'
  belongs_to :responsible, class_name: 'Employee'
  belongs_to :department
  belongs_to :contract
  belongs_to :billing_address

  has_one :client, through: :budget_item

  has_many :comments, class_name: 'OrderComment'
  has_many :targets, class_name: 'OrderTarget'

  has_and_belongs_to_many :employees
  has_and_belongs_to_many :contacts

  validates :kind_id, :responsible_id, :status_id, :department_id, presence: true

  scope :list, -> do
    includes(:budget_item).
    references(:budget_item).
    order(budget_item: :shortname)
  end

  # TODO: after create callback to initialize order targets

  def to_s
    budget_item.to_s
  end

end
