module ProjectmembershipHelper

  def list_label
    project? ? 'Mitarbeiter' : 'Projekte'
  end

  def project?
    @subject.kind_of?(Project)
  end

  def pm_link_params(prms = {})
    prms = link_params prms
    prms[:subject] ||= @subject.class.name.downcase
    prms
  end

end
