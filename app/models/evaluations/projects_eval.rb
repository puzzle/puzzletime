# encoding: utf-8

# abstract class for evaluation with project divisions
class ProjectsEval < Evaluation

  self.division_method   = :projects
  self.division_column   = 'projects.path_ids[1]'
  self.division_join     = :project
  self.label             = 'Projekte'
  self.sub_evaluation    = 'projectemployees'
  self.sub_projects_eval = 'subprojects'

  def account_id
    division.id if division
  end

  def division_supplement(user)
    [[:offered_hours, 'Offeriert']]
  end

end
