# encoding: utf-8

module ProjectmembershipHelper

  def list_label
    project? ? "Mitarbeiter" : "Projekte"
  end

  def project?
    @subject.kind_of?(Project)
  end

end
