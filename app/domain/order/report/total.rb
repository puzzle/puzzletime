# encoding: utf-8

class Order::Report::Total
  delegate :entries, to: :@report

  def initialize(report)
    @report = report
  end

  def parent_names
  end

  def to_s
    'Total'
  end

  def order
    nil
  end

  def status
    nil
  end

  def closed_at
    nil
  end

  def targets
    []
  end

  def major_chance
    nil
  end

  def major_risk
    nil
  end

  def offered_amount
    @offered_amount ||= entries.sum(&:offered_amount)
  end

  def offered_hours
    @offered_hours ||= entries.sum(&:offered_hours)
  end

  def supplied_amount
    entries.sum(&:supplied_amount)
  end

  def supplied_hours
    @supplied_hours ||= entries.sum(&:supplied_hours)
  end

  def billable_amount
    entries.sum(&:billable_amount)
  end

  def billable_hours
    entries.sum(&:billable_hours)
  end

  def billed_amount
    @billed_amount ||= entries.sum(&:billed_amount)
  end

  def billed_hours
    @billed_hours ||= entries.sum(&:billed_hours)
  end

  def offered_rate
    if offered_hours > 0
      (offered_amount / offered_hours).to_d
    elsif !entries.empty?
      entries.collect(&:offered_rate).compact.sum / entries.size
    end
  end

  def billability
    @billability ||= supplied_hours > 0 ? (billable_hours / supplied_hours * 100).round : nil
  end

  def billed_rate
    @billed_rate ||= billable_hours > 0 ? billed_amount / billable_hours : nil
  end

  def average_rate
    @average_rate ||= supplied_hours > 0 ? billable_amount / supplied_hours : nil
  end

  def target(_id)
  end
end
