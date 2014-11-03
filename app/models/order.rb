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
  include Closable

  ### ASSOCIATIONS

  belongs_to :kind, class_name: 'OrderKind'
  belongs_to :status, class_name: 'OrderStatus'
  belongs_to :responsible, class_name: 'Employee'
  belongs_to :department
  belongs_to :contract
  belongs_to :billing_address

  has_ancestor_through_work_item :client

  has_many :comments, class_name: 'OrderComment'
  has_many :targets, class_name: 'OrderTarget'
  has_descendants_through_work_item :accounting_posts

  has_and_belongs_to_many :employees
  has_and_belongs_to_many :contacts


  ### VALIDATIONS

  validates :kind_id, :responsible_id, :status_id, :department_id, presence: true
  validates :crm_key, uniqueness: true, allow_blank: true
  validate :work_item_parent_presence

  ### CALLBACKS

  after_initialize :set_default_status_id
  after_create :create_order_targets


  class << self
    def choosable_list
      result = connection.select_all(select('orders.id, work_items.path_shortnames, work_items.name').
                                     joins(:work_item).
                                     order('work_items.path_names'))
      result.collect { |row| ["#{row['path_shortnames']}: #{row['name']}", row['id']] }
    end
  end

  ### INSTANCE METHODS

  def parent_names
    work_item.path_names.split("\n")[0..-2].join(" #{Settings.work_items.path_separator} ")
  end

  def propagate_closed!
    if status.closed
      work_item.propagate_closed!(status.closed)
    else
      accounting_posts.each do |post|
        post.propagate_closed!
      end
    end
  end

  private

  def work_item_parent_presence
    if work_item && work_item.parent_id.nil?
      errors.add(:base, 'Kunde darf nicht leer sein')
    end
  end

  def set_default_status_id
    self.status_id ||= OrderStatus.list.pluck(:id).first
  end

  def create_order_targets
    TargetScope.find_each do |s|
      targets.create!(target_scope: s, rating: OrderTarget::RATINGS.first)
    end
  end

  def closed_changed?
    if status_id_changed?
      statuses = OrderStatus.find(status_id_change)
      statuses.first.closed? != statuses.last.closed?
    else
      false
    end
  end

end
