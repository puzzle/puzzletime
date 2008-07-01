module ProjectmembershipHelper

  def listLabel
    project? ? 'Mitarbeiter' : 'Projekte'
  end
  
  def project?
    @subject.kind_of?(Project)
  end
  
  def pmLinkParams(prms = {})
    prms = linkParams prms
    prms[:subject] ||= @subject.class.name.downcase
    prms
  end
  
end
