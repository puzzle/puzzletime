# frozen_string_literal: true

class Flatrate < ApplicationRecord
  belongs_to :accounting_post
  has_many :invoice_flatrates, dependent: :nullify
  has_many :invoices, through: :invoice_flatrates

  validates_date :active_from
  validates_date :active_to, allow_blank: true

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
    billed_flatrate_quantity = InvoiceFlatrate.where(flatrate_id: id).where.not(invoice_id: invoice_id).sum(:quantity) || 0
    Rails.logger.info("end_date: #{end_date}")
    stop_date = active_to.present? ? [end_date, active_to].compact.min : end_date

    accumulated_flatrate_quantity = 0
    (active_from..stop_date).select { |d| d.day == 1 }.each do |month_date|
      month_index = month_date.month - 1
      Rails.logger.info("cur_month_idx: #{month_index}")
      Rails.logger.info("cur_month_periodicity: #{periodicity[month_index]}")
      accumulated_flatrate_quantity += periodicity[month_index]
    end
    accumulated_flatrate_quantity - billed_flatrate_quantity
  end
end
