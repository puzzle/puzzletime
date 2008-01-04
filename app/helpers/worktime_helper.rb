module WorktimeHelper 
     
  def select_report_type(object_name = 'worktime', method = 'report_type', switch = true)
      htmlOptions = {}
      htmlOptions[:onchange] = 'switchvisibility();' if switch
      obj = instance_variable_get("@#{object_name}")
      select object_name, 
             method, 
             obj.report_types.collect {|type| [type.name, type.key]}, 
             {:selected => obj.send(method).key},
             htmlOptions
  end
  
  def genericPath
    'worktime'
  end

end
