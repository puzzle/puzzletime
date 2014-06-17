# encoding: utf-8

class ManagedProjectsEval < ProjectsEval

  self.division_method   = :managed_projects
  self.label             = 'Geleitete Projekte'
  self.total_details     = false

  def category_label
    'Kunde: ' + division.client.name
  end

  def sum_times_grouped(period)
    query = Worktime.joins(:project).
                     joins('INNER JOIN projectmemberships pm ON pm.project_id = ANY (projects.path_ids)').
                     where(type: 'Projecttime').
                     where(pm: { active: true, projectmanagement: true, employee_id: category.id }).
                     group('pm.project_id')
    query = query.where('work_date BETWEEN ? AND ?', period.startDate, period.endDate) if period
    query.sum(:hours)
  end

  def sum_total_times(period = nil)
    category.sum_managed_projects_worktime(period)
  end

end
