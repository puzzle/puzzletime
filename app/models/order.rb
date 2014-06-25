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
#  target_cost        :string(255)
#  target_date        :string(255)
#  target_quality     :string(255)
#  targets_comment    :string(255)
#  targets_updated_at :datetime
#  created_at         :datetime
#  updated_at         :datetime
#

class Order < ActiveRecord::Base

  TARGET_RATINGS = %w(green orange red)

  belongs_to :budget_item, class_name: 'Project'
  belongs_to :kind, class_name: 'OrderKind'
  belongs_to :status, class_name: 'OrderStatus'
  belongs_to :responsible, class_name: 'Employee'
  belongs_to :department
  belongs_to :contract
  belongs_to :billing_address

  has_one :client, through: :budget_item

  has_many :comments, class_name: 'OrderComment'

  has_and_belongs_to_many :employees
  has_and_belongs_to_many :contacts

  validates :kind_id, :responsible_id, :status_id, :department_id, presence: true
  validates :target_cost, :target_date, :target_quality, inclusion: TARGET_RATINGS
  validates :targets_comment, presence: { if: :target_critical? }

  scope :list, -> do
    includes(:budget_item).
    references(:budget_item).
    order(budget_item: :shortname)
  end

  def to_s
    budget_item.to_s
  end

  def target_critical?
    [target_cost, target_date, target_quality].any? { |t| t != TARGET_RATINGS.first }
  end
end
