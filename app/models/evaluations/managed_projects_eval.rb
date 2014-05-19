# encoding: utf-8

class ManagedProjectsEval < ProjectsEval

  DIVISION_METHOD   = :managed_projects
  LABEL             = 'Geleitete Projekte'
  TOTAL_DETAILS     = false

  def category_label
    'Kunde: ' + division.client.name
  end

  def sum_total_times(period = nil)
    category.sum_managed_projects_worktime(period)
  end

end
