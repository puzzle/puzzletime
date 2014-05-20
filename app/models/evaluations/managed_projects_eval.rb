# encoding: utf-8

class ManagedProjectsEval < ProjectsEval

  self.division_method   = :managed_projects
  self.label             = 'Geleitete Projekte'
  self.total_details     = false

  def category_label
    'Kunde: ' + division.client.name
  end

  def sum_total_times(period = nil)
    category.sum_managed_projects_worktime(period)
  end

end
