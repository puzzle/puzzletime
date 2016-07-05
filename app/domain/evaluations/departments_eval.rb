# encoding: utf-8

class DepartmentsEval < Evaluation
  self.division_column   = 'orders.department_id'
  self.division_join     = 'INNER JOIN work_items ON work_items.id = worktimes.work_item_id ' \
                           'INNER JOIN orders ON orders.work_item_id = ANY (work_items.path_ids)'
  self.sub_evaluation   = 'departmentorders'
  self.label            = 'Geschäftsbereiche'
  self.total_details    = false
  self.billing_hours    = true

  def initialize
    super(Department)
  end
end
