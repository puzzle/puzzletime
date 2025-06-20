# frozen_string_literal: true

class Flatrate < ApplicationRecord
  include Invoicing

  belongs_to :accounting_post, inverse_of: :flatrates
  has_many :invoice_flatrates, dependent: :nullify
  has_many :invoices, through: :invoice_flatrates

  validates_date :active_from
  validates_date :active_to, allow_blank: true
  validates :unit, inclusion: Invoicing::Units::OPTIONS.values

  def label_verbose
    "#{name} (#{accounting_post.name})"
  end

  (0..11).each do |i|
    define_method(:"periodicity_#{i}") do
      periodicity[i].to_i
    rescue StandardError
      0
    end

    define_method(:"periodicity_#{i}=") do |val|
      current = periodicity.dup
      current[i] = val.to_i
      self.periodicity = current # triggers ActiveRecord change tracking
    end
  end

  # Ensure periodicity is always an array of 12 integers
  def periodicity
    super&.map(&:to_i)&.fill(0, super.size...12) || Array.new(12, 0)
  end

  def periodicity=(vals)
    super(Array(vals).map(&:to_i).fill(0, vals.size...12))
  end

  # takes in a date d and returns the amount of billed flatrates minus the amount of planned flatrates
  # (according to flatrate schedule) since the beginning of the contract until min(d, contract end date)
  def not_billed_flatrates_quantity(end_date, invoice_id)
    billed_flatrate_quantity = InvoiceFlatrate.where(flatrate_id: id)
                                              .where.not(invoice_id: invoice_id)
                                              .sum(:quantity) || 0

    [accumulated_flatrate_quantity_at_date(active_from, end_date) - billed_flatrate_quantity, 0].max
  end

  def accumulated_flatrate_quantity_at_date(start_date, end_date)
    end_date = [
      end_date,
      (active_to.present? ? active_to.end_of_month : nil),
      accounting_post.order.contract.end_date.end_of_month
    ].compact.min

    start_date = [
      start_date,
      active_from.beginning_of_month, 
      accounting_post.order.contract.start_date.beginning_of_month
    ].compact.max

    Rails.logger.info("startdate flatrate calc: #{start_date}")

    accumulated_flatrate_quantity = 0
    (start_date..end_date).select { |d| d.day == 1 }.each do |month_date|
      month_index = month_date.month - 1
      accumulated_flatrate_quantity += periodicity[month_index]
    end
    
    Rails.logger.info("accumulated_flatrate_quantity flatrate calc: #{accumulated_flatrate_quantity}")

    accumulated_flatrate_quantity
  end
end
