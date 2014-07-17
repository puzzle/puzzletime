# encoding: utf-8

class ManagedProjectsEval < ProjectsEval

  self.division_method   = :managed_projects
  self.label             = 'Geleitete Projekte'
  self.total_details     = false

  def category_label
    'Kunde: ' + division.client.name
  end

  def sum_times_grouped(period)
    Worktime.joins(:project).
             joins('INNER JOIN orders ON orders.work_item_id = ANY (projects.path_ids)').
             where(type: 'Projecttime').
             where(orders: { responsible_id: category.id }).
             in_period(period).
             group('orders.work_item_id').
             sum(:hours)
  end

  def sum_total_times(period = nil)
    Employee.joins('LEFT JOIN orders ON employees.id = orders.responsible_id').
             joins('LEFT JOIN projects P ON orders.work_item_id = P.id').
             joins('LEFT JOIN projects C ON P.id = ANY (C.path_ids)').
             joins('LEFT JOIN worktimes T ON C.id = T.project_id').
             where(employees: { id: 1 }).
             merge(Worktime.in_period(period)).
             sum(:hours).to_f
  end

end
