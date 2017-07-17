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
#  crm_key            :string
#  created_at         :datetime
#  updated_at         :datetime
#  completed_at       :date
#  committed_at       :date
#  closed_at          :date
#

class Order < ActiveRecord::Base

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
  has_descendants_through_work_item :accounting_posts

  has_many :order_team_members, -> { list }, dependent: :destroy
  has_many :team_members, through: :order_team_members, source: :employee
  has_many :order_contacts, -> { list }, dependent: :destroy
  has_many :contacts, through: :order_contacts
  has_many :invoices, dependent: :destroy

  accepts_nested_attributes_for :order_team_members,
                                :order_contacts,
                                reject_if: :all_blank,
                                allow_destroy: true

  ### VALIDATIONS

  validates_by_schema
  validates :work_item_id, uniqueness: true
  validates :kind_id, :responsible_id, :status_id, :department_id, presence: true
  validates :crm_key, uniqueness: true, allow_blank: true
  validate :work_item_parent_presence

  ### CALLBACKS

  before_update :set_closed_at
  before_validation :set_self_in_nested
  after_initialize :set_default_status_id
  after_create :create_order_targets

  scope :minimal, lambda {
    select('orders.id, work_items.name, work_items.path_names, work_items.path_shortnames')
  }

  class << self
    def order_by_target_scope(target_scope_id, desc = false)
      joins('LEFT JOIN order_targets sort_target ' \
              'ON sort_target.order_id = orders.id ').
        where('sort_target.target_scope_id = ? OR sort_target.id IS NULL', target_scope_id).
        reorder("sort_target.rating #{desc ? 'asc' : 'desc'}")
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
    billing_address_id || client.billing_addresses.list.pluck(:id).first
  end

  def set_default_status_id
    self.status_id ||= OrderStatus.list.pluck(:id).first
  end

  private

  def work_item_parent_presence
    if work_item && work_item.parent_id.nil?
      errors.add(:base, 'Kunde darf nicht leer sein')
    end
  end

  def set_self_in_nested
    return unless OrderTeamMember.table_exists? # required until all instances are migrated
    # don't try to set self in frozen nested attributes (-> marked for destroy)
    [order_team_members, order_contacts].each do |c|
      c.each do |e|
        unless e.frozen?
          e.order = self
        end
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
