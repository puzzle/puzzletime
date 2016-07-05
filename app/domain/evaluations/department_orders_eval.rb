# encoding: utf-8

class DepartmentOrdersEval < WorkItemsEval
  self.division_join     = nil
  self.division_column   = 'orders.work_item_id'

  def initialize(department_id)
    super(Department.find(department_id))
  end

  def divisions(_period = nil)
    WorkItem.joins(:order).includes(:order).where(orders: { department_id: category.id }).list
  end

  def division_supplement(_user, period = nil)
    supplement = []
    if show_month_end_completions?(_user, period)
      supplement << [:order_month_end_completions, 'Abschluss erledigt', 'left']
    end
    supplement
  end

  private

  def show_month_end_completions?(user, period)
    ability = Ability.new(user)
    past_month = Period.parse('-1m')
    period.present? &&
        period.start_date == past_month.start_date &&
        period.end_date == past_month.end_date &&
        category.orders.any? { |order| ability.can?(:update_month_end_completions, order) }
  end
end
