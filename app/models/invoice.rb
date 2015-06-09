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
#  add_vat            :boolean          default(TRUE), not null
#  billing_address_id :integer          not null
#  invoicing_key      :string
#

class Invoice < ActiveRecord::Base

  STATUSES = %w(draft sent paid)

  belongs_to :order
  belongs_to :billing_address

  has_many :ordertimes, dependent: :nullify


  validates_date :billing_date, :due_date, :period_from, :period_to
  validates :invoicing_key, uniqueness: true, allow_blank: true
  validates :status, inclusion: STATUSES
  validate :assert_positive_period
  validate :assert_billing_address_belongs_to_order_client
  validate :assert_order_has_contract

  before_validation :set_default_status
  before_validation :generate_reference, on: :create
  before_validation :generate_due_date
  before_create :lock_client_invoice_number
  after_create :update_client_invoice_number


  def title
    title = order.name
    if order.contract && order.contract.number?
      title += " gemäss Vertrag #{order.contract.number}"
    end
    title
  end

  def period
    "#{I18n.l(period_from)} - #{I18n.l(period_to)}"
  end

  def payment_period
    order.contract.try(:payment_period)
  end

  def contract_reference
    order.contract.try(:reference)
  end

  private

  def lock_client_invoice_number
    order.client.lock!
    generate_reference
  end

  def update_client_invoice_number
    order.client.update_column(:last_invoice_number, order.client.last_invoice_number + 1)
  end

  def generate_reference
    self.reference = "#{order.client.shortname}#{order.shortname}#{order.department.shortname}" \
                     "#{'%04d' % (order.client.last_invoice_number + 1)}"
  end

  def generate_due_date
    self.due_date ||= billing_date + payment_period.days if order.contract
  end

  def set_default_status
    self.status ||= STATUSES.first
  end

  def assert_positive_period
    if period_to && period_from && period_to < period_from
      errors.add(:period_to, 'muss nach von sein.')
    end
  end

  def assert_billing_address_belongs_to_order_client
    if billing_address && order && billing_address.client_id != order.client.id
      errors.add(:billing_address_id, 'muss zum Auftragskunden gehören.')
    end
  end

  def assert_order_has_contract
    unless order.contract
      errors.add(:order_id, 'muss einen definierten Vertrag haben.')
    end
  end

end
