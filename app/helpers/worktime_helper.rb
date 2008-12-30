module WorktimeHelper 
     
  def select_report_type(auto_start_stop_type = false)
      options = ReportType::INSTANCES
      options = [AutoStartType::INSTANCE] + options if auto_start_stop_type
      select 'worktime', 
             'report_type', 
             options.collect {|type| [type.name, type.key]}, 
             {:selected => @worktime.report_type.key},
             {:onchange => 'switchvisibility();'}
  end
  
  def genericPath
    'worktime'
  end

end
