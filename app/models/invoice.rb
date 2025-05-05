# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# == Schema Information
#
# Table name: invoices
#
#  id                 :integer          not null, primary key
#  order_id           :integer          not null
#  billing_date       :date             not null
#  due_date           :date             not null
#  total_amount       :decimal(12, 2)   not null
#  total_hours        :float            not null
#  reference          :string           not null
#  period_from        :date             not null
#  period_to          :date             not null
#  status             :string           not null
#  billing_address_id :integer          not null
#  invoicing_key      :string
#  created_at         :datetime
#  updated_at         :datetime
#  grouping           :integer          default("accounting_posts"), not null
#

class Invoice < ApplicationRecord
  STATUSES = %w[draft sent paid partially_paid cancelled deleted unknown].freeze

  enum :grouping, { 'accounting_posts' => 0, 'employees' => 1, 'manual' => 2 }

  belongs_to :order
  belongs_to :billing_address

  has_many :ordertimes, dependent: :nullify

  has_and_belongs_to_many :work_items
  has_and_belongs_to_many :employees

  validates_by_schema
  validates_date :billing_date, :due_date, :period_from, :period_to
  validates :invoicing_key, uniqueness: true, allow_blank: true
  validates :status, inclusion: STATUSES
  validate :assert_positive_period
  validate :assert_order_has_contract
  validate :assert_order_not_closed

  before_validation :set_default_status
  before_validation :generate_reference, on: :create
  before_validation :generate_due_date
  before_validation :update_totals
  before_save :save_remote_invoice, if: -> { Invoicing.instance.present? }
  before_save :assign_worktimes
  before_create :lock_client_invoice_number
  after_create :update_client_invoice_number
  after_destroy :delete_remote_invoice, if: -> { Invoicing.instance.present? }
  after_save :update_order_billing_address

  protect_if :paid?, 'Bezahlte Rechnungen können nicht gelöscht werden.'
  protect_if :order_closed?, 'Rechnungen von geschlossenen Aufträgen können nicht gelöscht werden.'

  scope :list, -> { order(billing_date: :desc) }

  scope :in_period, (lambda do |period|
    if period
      where(period.where_condition('billing_date'))
    else
      all
    end
  end)

  def title
    title = order.name
    title += " gemäss Vertrag #{order.contract.number}" if order.contract&.number?
    title
  end

  def to_s
    reference
  end

  def period
    ::Period.new(period_from, period_to)
  end

  def payment_period
    order.contract.try(:payment_period)
  end

  def contract_reference
    order.contract.try(:reference)
  end

  def manual_invoice?
    manual?
  end

  def calculated_total_amount
    total = positions.sum(&:total_amount)
    round_to_5_cents(total)
  end

  def calculated_total_hours
    positions.sum(&:total_hours)
  end

  def billing_client
    billing_address.try(:client) ||
      order.billing_address.try(:client) ||
      order.client
  end

  def billing_client_id
    billing_client.try(:id)
  end

  def order_closed?
    order.status.closed?
  end

  def destroyable?
    draft?
  end

  STATUSES.each do |s|
    define_method(:"#{s}?") do
      status == s
    end
  end

  private

  def positions
    @positions ||= build_positions
  end

  def build_positions
    case grouping.to_s
    when 'manual' then [manual_position]
    when 'employees' then employee_positions
    else accounting_post_positions
    end
  end

  def manual_position
    Invoicing::Position.new(AccountingPost.new(offered_rate: 1), 1, 'Manuell')
  end

  def accounting_post_positions
    worktimes.group(:work_item_id).sum(:hours).collect do |work_item_id, hours|
      post = AccountingPost.find_by!(work_item_id:)
      Invoicing::Position.new(post, hours)
    end.sort_by(&:name)
  end

  def employee_positions
    worktimes.group(:work_item_id, :employee_id).sum(:hours).collect do |groups, hours|
      post = AccountingPost.find_by!(work_item_id: groups.first)
      employee = Employee.find(groups.last)
      Invoicing::Position.new(post, hours, "#{post.name} - #{employee}")
    end.sort_by(&:name)
  end

  def worktimes
    Ordertime.in_period(period)
             .where(billable: true)
             .where(work_item_id: work_item_ids)
             .where(employee_id: employee_ids)
             .where(invoice_id: [id, nil])
  end

  def lock_client_invoice_number
    order.client.lock!
    generate_reference
  end

  def update_client_invoice_number
    order.client.update_column(:last_invoice_number, order.client.last_invoice_number + 1)
  end

  def update_order_billing_address
    return unless order.billing_address_id != billing_address_id

    order.update_column(:billing_address_id, billing_address_id)
  end

  def update_totals
    if manual_invoice?
      self.total_hours = 0
      self.total_amount = calculated_total_amount if grouping_changed?
    else
      self.total_hours = positions.sum(&:total_hours)
      self.total_amount = calculated_total_amount
    end
  end

  def generate_reference
    reference_segments = [
      order.client.shortname,
      order.category.try(:shortname),
      order.shortname,
      order.department.shortname,
      format('%04d', order.client.last_invoice_number + 1)
    ]
    self.reference = reference_segments.compact.join
  end

  def generate_due_date
    self.due_date ||= billing_date + payment_period.days if order.contract
  end

  def set_default_status
    self.status ||= STATUSES.first
  end

  def assert_positive_period
    return unless period_to && period_from && period_to < period_from

    errors.add(:period_to, 'muss nach von sein.')
  end

  def assert_order_has_contract
    return if order.contract

    errors.add(:order_id, 'muss einen definierten Vertrag haben.')
  end

  def assert_order_not_closed
    return unless order_closed?

    errors.add(:order, 'darf nicht geschlossen sein.')
  end

  def save_remote_invoice
    self.invoicing_key = Invoicing.instance.save_invoice(self, positions)
  rescue Invoicing::Error => e
    errors.add(:base, "Fehler im Invoicing Service: #{e.message}")
    Rails.logger.error("#{e.class.name}: #{e.message}\n#{e.backtrace.join("\n")}")
    throw :abort
  end

  def delete_remote_invoice
    Invoicing.instance.delete_invoice(self)
  rescue Invoicing::Error => e
    # Ignore "no rights / not found" errors, the invoice does not exist remotly in this case.
    unless e.code == 15_016
      errors.add(:base, "Fehler im Invoicing Service: #{e.message}")
      Rails.logger.error("#{e.class.name}: #{e.message}\n#{e.backtrace.join("\n")}")
      raise ActiveRecord::Rollback
    end
  end

  def assign_worktimes
    self.ordertimes = manual_invoice? ? [] : worktimes
  end

  def round_to_5_cents(amount)
    (amount * 20).round / 20.0
  end
end
