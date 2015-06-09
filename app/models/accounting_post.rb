# encoding: utf-8
# == Schema Information
#
# Table name: accounting_posts
#
#  id                     :integer          not null, primary key
#  work_item_id           :integer          not null
#  portfolio_item_id      :integer
#  reference              :string(255)
#  offered_hours          :float
#  offered_rate           :decimal(12, 2)
#  offered_total          :decimal(12, 2)
#  discount_percent       :integer
#  discount_fixed         :integer
#  remaining_hours        :integer
#  billable               :boolean          default(TRUE), not null
#  description_required   :boolean          default(FALSE), not null
#  ticket_required        :boolean          default(FALSE), not null
#  closed                 :boolean          default(FALSE), not null
#  from_to_times_required :boolean          default(FALSE), not null
#

class AccountingPost < ActiveRecord::Base

  include BelongingToWorkItem
  include Closable

  ### ASSOCIATIONS

  belongs_to :portfolio_item

  has_ancestor_through_work_item :order
  has_ancestor_through_work_item :client

  ### CALLBACKS

  before_validation :derive_offered_fields
  before_update :remember_old_work_item_id
  after_create :move_order_accounting_post_work_item
  after_update :handle_changed_work_item

  ### VALIDATIONS

  validates :work_item_id, uniqueness: true
  validates :offered_rate, presence: true
  validates :portfolio_item, presence: true
  validate :check_booked_on_order


  ### INSTANCE METHODS

  def validate_worktime(worktime)
    if worktime.report_type != AutoStartType::INSTANCE
      if description_required? && worktime.description.blank?
        worktime.errors.add(:description, 'Es muss eine Bemerkung angegeben werden')
      end

      if ticket_required? && worktime.ticket.blank?
        worktime.errors.add(:ticket, 'Es muss ein Ticket angegeben werden')
      end

      if from_to_times_required?
        worktime.errors.add(:from_start_time, 'muss angegeben werden') if worktime.from_start_time.blank?
        worktime.errors.add(:to_end_time, 'muss angegeben werden') if worktime.to_end_time.blank?
      end
    end
  end

  def attach_work_item(order, attributes, book_on_order = false)
    attributes ||= {}
    @order = order
    if book_on_order
      self.work_item = order.work_item
    elsif new_record? || work_item_id == order.work_item_id
      self.work_item = WorkItem.new(attributes.merge(parent_id: order.work_item_id))
    else
      self.work_item_attributes = attributes
    end
  end

  def booked_on_order?
    order.present? && work_item_id == order.work_item_id
  end

  def book_on_order_allowed?
    return @book_on_order_allowed unless @book_on_order_allowed.nil?

    existing = order.accounting_posts.pluck(:id)
    @book_on_order_allowed = existing.blank? || existing == [id]
  end

  def offered_days
    offered_hours.to_f / WorkingCondition.todays_value(:must_hours_per_day)
  end

  def no_discount?
    !(discount_fixed? || discount_percent?)
  end

  def to_s
    work_item.label_verbose
  end

  def propagate_closed!
    work_item.propagate_closed!(order.status.closed? || closed?)
  end

  private

  def derive_offered_fields
    if !offered_total? && offered_hours? && offered_rate?
      self.offered_total = offered_hours * offered_rate
    end
  end

  def check_booked_on_order
    if booked_on_order? && !book_on_order_allowed?
      errors.add(:base, "'Direkt auf Auftrag buchen' gewählt, aber es existieren bereits andere Buchungspositionen")
      false
    end
  end

  def remember_old_work_item_id
    @old_work_item_id = work_item_id_was
  end

  def handle_changed_work_item
    return if work_item_id == @old_work_item_id

    old_item = WorkItem.find(@old_work_item_id)
    old_item.move_times!(work_item_id)
    old_item.destroy! unless old_item.id == order.work_item_id
  end

  def move_order_accounting_post_work_item
    return if work_item_id == order.work_item_id
    post = order.accounting_posts.where(work_item_id: order.work_item_id).first
    if post
      post.work_item = WorkItem.new(name: order.work_item.name,
                                    shortname: order.work_item.shortname,
                                    parent_id: order.work_item.id,
                                    closed: post.closed? || order.status.closed?)
      post.save!
      order.work_item.move_times!(post.work_item)
    end
  end

  def exclusive_work_item?
    work_item.order.nil?
  end

end
