# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

module WorktimeHelper 
     
  def select_report_type
      '<select id="report_type" name="worktime[report_type]" onChange="switchvisibility();">' +
      option_report_type(Worktime::TYPE_START_STOP, 'Start-Stop Zeit') + 
      option_report_type(Worktime::TYPE_HOURS_DAY, 'Stunden/Tag') + 
      option_report_type(Worktime::TYPE_HOURS_WEEK, 'Stunden/Woche') + 
      option_report_type(Worktime::TYPE_HOURS_MONTH, 'Stunden/Monat') + 
      '</select>'
  end
  
  def option_report_type(type, label)
    "<option value=\"#{type}\"" + 
    (type == @worktime.report_type ? 'selected="selected"' : '' ) + 
    ">#{label}</option>" 
  end
  
end
