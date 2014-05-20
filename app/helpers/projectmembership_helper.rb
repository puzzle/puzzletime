# encoding: utf-8

module ProjectmembershipHelper

  def membership_list_label
    project? ? "Mitarbeiter" : "Projekte"
  end

  def membership_other_label(membership)
    project? ? membership.employee.label : membership.project.label_verbose
  end

  private

  def project?
    @subject.kind_of?(Project)
  end

end
