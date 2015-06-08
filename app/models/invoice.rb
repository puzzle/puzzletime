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

  STATUSES = %w(draft sent payed)

  belongs_to :order
  belongs_to :billing_address

  has_many :ordertimes, dependent: :nullify


  validates_date :billing_date, :due_date, :period_from, :period_to
  validates :status, inclusion: STATUSES
  validate :assert_positive_period
  validate :assert_billing_address_belongs_to_order_client


  before_validate :generate_reference, on: :create
  before_validate :generate_due_date


  def title
    "#{order.name}#{" gemäss Vertrag #{order.contract.number}" if order.contract.number?}"
  end

  def period
    "#{I18n.l(period_from)} - #{I18n.l(period_to)}"
  end

  def payment_period
    order.contract.payment_period
  end

  def contract_reference
    order.contract.reference
  end

  private

  def generate_reference
    # TODO, PrefixKunde.KurznameAuftrag.KurznameOrganisationseinheit.KurznameLaufnummerProKunde
  end

  def generate_due_date
    self.due_date ||= billing_date + payment_period.days
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

end
