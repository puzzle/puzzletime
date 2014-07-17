# encoding: utf-8
# == Schema Information
#
# Table name: orders
#
#  id                 :integer          not null, primary key
#  work_item_id       :integer          not null
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

  include BelongingToWorkItem

  belongs_to :kind, class_name: 'OrderKind'
  belongs_to :status, class_name: 'OrderStatus'
  belongs_to :responsible, class_name: 'Employee'
  belongs_to :department
  belongs_to :contract
  belongs_to :billing_address

  has_one_through_work_item :client

  has_many :comments, class_name: 'OrderComment'
  has_many :targets, class_name: 'OrderTarget'
  has_many_through_work_item :accounting_posts
  has_many_through_work_item :worktimes

  has_and_belongs_to_many :employees
  has_and_belongs_to_many :contacts

  validates :kind_id, :responsible_id, :status_id, :department_id, presence: true
  validate :work_time_parent_presence

  # TODO: validate only one order per work_items path_ids
  # TODO: after create callback to initialize order targets
  # TODO propagate status closed to work items when changed

  scope :list, -> do
    includes(:work_item).
    references(:work_item).
    order('work_items.path_shortnames')
  end

  def to_s
    work_item.to_s
  end

  def status_id
    super || OrderStatus.list.pluck(:id).first
  end

  private

  def work_time_parent_presence
    if work_item && work_item.parent_id.nil?
      work_item.errors.add(:parent_id, :blank)
    end
  end

end
