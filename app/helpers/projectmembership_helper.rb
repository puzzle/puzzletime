module ProjectmembershipHelper

  def listLabel
    project? ? 'Mitarbeiter' : 'Projekte'
  end
  
  def project?
    @subject.kind_of?(Project)
  end
  
  def pmLinkParams(prms = {})
    prms[:group_id] ||= params[:group_id]
    prms[:page] ||= params[:page]
    prms[:group_page] ||= params[:group_page]
    prms[:subject] ||=  @subject.class.name.downcase
    prms
  end
  
end
