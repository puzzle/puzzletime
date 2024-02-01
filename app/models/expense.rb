# == Schema Information
#
# Table name: expenses
#
#  id                 :bigint(8)        not null, primary key
#  employee_id        :bigint(8)        not null
#  kind               :integer          not null
#  status             :integer          default("pending"), not null
#  amount             :decimal(12, 2)   not null
#  payment_date       :date             not null
#  description        :text             not null
#  reason             :text
#  reviewer_id        :bigint(8)
#  reviewed_at        :datetime
#  order_id           :bigint(8)
#  reimbursement_date :date
#  submission_date    :date
#

class Expense < ActiveRecord::Base
  belongs_to :order
  belongs_to :employee
  belongs_to :reviewer, class_name: 'Employee'

  has_one_attached :receipt

  enum kind:   { project: 0, training: 1, sales: 2, support: 3, other: 4 }
  enum status: { pending: 0, deferred: 1, approved: 2, rejected: 3 }

  validates_by_schema

  validate :assert_payment_month, if: :approved?
  validates :reviewer, :reviewed_at, presence: true, if: -> { approved? || rejected? }

  scope :list, -> { order(payment_date: :desc) }

  def to_s
    kind_value
  end

  def status_value
    self.class.status_value(status)
  end

  def kind_value
    self.class.kind_value(kind)
  end

  def reimbursement_month
    I18n.l(reimbursement_date, format: :month) if reimbursement_date
  end

  def assert_payment_month
    errors.add(:reimbursement_month, :blank) if reimbursement_date.blank?
  end

  def self.reimbursement_months
    statement = 'SELECT DISTINCT ' \
                'EXTRACT(YEAR FROM reimbursement_date)::int AS year, ' \
                'EXTRACT(MONTH FROM reimbursement_date)::int AS month ' \
                'FROM expenses ' \
                'WHERE reimbursement_date IS NOT NULL ' \
                'ORDER BY year, month'
    connection.select_rows(statement).collect { |year, month| Date.new(year, month, 1) }
  end

  def self.payment_years(employee)
    statement = 'SELECT DISTINCT ' \
                'EXTRACT(YEAR FROM payment_date)::int AS year ' \
                'FROM expenses ' \
                "WHERE employee_id = #{employee.id} " \
                'ORDER BY year'
    connection.select_values(statement).collect { |year| Date.new(year, 1, 1) }
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
      month_name = I18n.l(expense.payment_date, format: :month)
      memo[month_name] ||= []
      memo[month_name] << expense
    end
  end
end
