# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# {{{
# == Schema Information
#
# Table name: orders
#
#  id                 :integer          not null, primary key
#  closed_at          :date
#  committed_at       :date
#  completed_at       :date
#  crm_key            :string
#  major_chance_value :integer
#  major_risk_value   :integer
#  created_at         :datetime
#  updated_at         :datetime
#  billing_address_id :integer
#  contract_id        :integer
#  department_id      :integer
#  kind_id            :integer
#  responsible_id     :integer
#  status_id          :integer
#  work_item_id       :integer          not null
#
# Indexes
#
#  index_orders_on_billing_address_id  (billing_address_id)
#  index_orders_on_contract_id         (contract_id)
#  index_orders_on_department_id       (department_id)
#  index_orders_on_kind_id             (kind_id)
#  index_orders_on_responsible_id      (responsible_id)
#  index_orders_on_status_id           (status_id)
#  index_orders_on_work_item_id        (work_item_id)
#
# }}}

class Order < ApplicationRecord
  include BelongingToWorkItem
  include Closable
  include Evaluatable

  ### ASSOCIATIONS

  belongs_to :kind, class_name: 'OrderKind', optional: true
  belongs_to :status, class_name: 'OrderStatus', optional: true
  belongs_to :responsible, class_name: 'Employee', optional: true
  belongs_to :department, optional: true
  belongs_to :contact, optional: true
  belongs_to :contract, optional: true, dependent: :destroy
  belongs_to :billing_address, optional: true

  has_ancestor_through_work_item :client

  has_many :comments, class_name: 'OrderComment', dependent: :destroy
  has_many :targets, class_name: 'OrderTarget', dependent: :destroy
  has_many :order_uncertainties, dependent: :destroy
  has_many :order_risks, class_name: 'OrderRisk'
  has_many :order_chances, class_name: 'OrderChance'
  has_descendants_through_work_item :accounting_posts

  has_many :order_team_members, -> { list }, dependent: :destroy
  has_many :team_members, through: :order_team_members, source: :employee
  has_many :order_contacts, -> { list }, dependent: :destroy
  has_many :contacts, through: :order_contacts
  has_many :additional_crm_orders, dependent: :destroy
  has_many :invoices, dependent: :destroy

  accepts_nested_attributes_for :order_team_members,
                                :order_contacts,
                                :additional_crm_orders,
                                reject_if: :all_blank,
                                allow_destroy: true

  ### VALIDATIONS

  validates_by_schema
  validates :work_item_id, uniqueness: true
  validates :kind_id, :responsible_id, :status_id, :department_id, presence: true
  validates :crm_key, uniqueness: true, allow_blank: true
  validate :work_item_parent_presence

  ### CALLBACKS

  after_initialize :set_default_status_id
  before_validation :set_self_in_nested
  after_create :create_order_targets
  before_update :set_closed_at

  scope :minimal, lambda {
    select('orders.id, orders.status_id, orders.work_item_id, work_items.name, work_items.path_names, work_items.path_shortnames')
  }

  scope :open, -> { where(status: OrderStatus.open) }

  class << self
    def order_by_target_scope(target_scope_id, desc = false)
      joins('LEFT JOIN order_targets sort_target ' \
            'ON sort_target.order_id = orders.id ')
        .where('sort_target.target_scope_id = ? OR sort_target.id IS NULL', target_scope_id)
        .reorder("sort_target.rating #{desc ? 'asc' : 'desc'}")
    end
  end

  ### INSTANCE METHODS

  def category
    work_item.parent unless work_item.parent == client
  end

  def parent_names
    work_item.path_names.split("\n")[0..-2].join(" #{Settings.work_items.path_separator} ")
  end

  def propagate_closed!
    if status.closed?
      work_item.propagate_closed!(status.closed)
    else
      work_item.update_column(:closed, false)
      accounting_posts.each do |post|
        post.work_item.propagate_closed!(post.closed?)
      end
    end
  end

  def label
    name
  end

  def default_billing_address_id
    billing_address_id || client.billing_addresses.list.pick(:id)
  end

  def set_default_status_id
    self.status_id ||= OrderStatus.defaults.pick(:id)
  end

  def major_risk
    OrderUncertainty.risk(major_risk_value)
  end

  def major_chance
    OrderUncertainty.risk(major_chance_value)
  end

  def label_with_workitem_path
    "#{work_item.path_shortnames}: #{name}"
  end

  private

  def work_item_parent_presence
    return unless work_item && work_item.parent_id.nil?

    errors.add(:base, 'Kunde darf nicht leer sein')
  end

  def set_self_in_nested
    return unless OrderTeamMember.table_exists? # required until all instances are migrated

    # don't try to set self in frozen nested attributes (-> marked for destroy)
    [order_team_members, order_contacts].each do |c|
      c.each do |e|
        e.order = self unless e.frozen?
      end
    end
  end

  def set_closed_at
    if status.closed
      self.closed_at ||= Time.zone.today
    else
      self.closed_at = nil
    end
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
