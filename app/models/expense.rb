class Expense < ActiveRecord::Base
  belongs_to :order
  belongs_to :employee
  belongs_to :reviewer, class_name: 'Employee'

  has_one_attached :receipt

  enum kind:   %i(project training sales support other)
  enum status: %i(pending approved rejected)

  validates_by_schema

  scope :list, -> { order(:payment_date) }

  def to_s
    kind_value
  end

  def status_value
    self.class.status_value(status)
  end

  def kind_value
    self.class.kind_value(kind)
  end

  def self.kind_value(value)
    human_attribute_name("kinds.#{value}")
  end

  def self.status_value(value)
    human_attribute_name("statuses.#{value}")
  end

  def self.by_month(relation, year)
    relation = relation.where(payment_date: Date.new(year.to_i, 1, 1).all_year) if year
    relation.each_with_object({}) do |expense, memo|
      month_name = I18n.l(expense.payment_date, format: '%B, %Y')
      memo[month_name] ||= []
      memo[month_name] << expense
    end
  end
end
