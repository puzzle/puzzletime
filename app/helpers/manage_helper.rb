
module ManageHelper

  def inputField(field)
    case modelClass.columnType(field[0])
      when :date then date_calendar_field 'entry', field[0], field[1]
      when :boolean then check_box 'entry', field[0]
      when :float, :integer then text_field 'entry', field[0], :size => 15
      when :text then text_area 'entry', field[0], {:rows => 5, :cols => 30}
      when :report_type then select 'entry', field[0], 
                ReportType::INSTANCES.collect {|type| [type.name, type.key]}, 
               {:selected => @entry.send(field[0]).key}
      else text_field 'entry', field[0], :size => 30
      end
  end
  
  def dataField(entry, attribute)
    options = case modelClass.columnType(attribute)
                when :date, :float, :integer then ' align="right"'
                when :boolean then ' align="center"'
                else ''
                end
    "<td#{options}>#{h formatColumn(attribute, entry.send(attribute))}</td>"
  end 
  
  def linkParams(prms = {})
    prms[:page]        ||= params[:page]
    prms[:groups]      ||= params[:groups]
    prms[:group_ids]   ||= params[:group_ids]
    prms[:group_pages] ||= params[:group_pages]
    prms
  end
  
  def child_group_params(key, id, page, prms = {})
    prms[:groups]      ||= params[:groups].to_a + [key]
    prms[:group_ids]   ||= params[:group_ids].to_a + [id]
    prms[:group_pages] ||= params[:group_pages].to_a + [page] 
    prms
  end
  
  def group_params(prms = {})
    prms[:page]        ||= params[:group_pages].to_a.last
    prms[:groups]      ||= params[:groups][0..-2] 
    prms[:group_ids]   ||= params[:group_ids][0..-2]
    prms[:group_pages] ||= params[:group_pages][0..-2] 
    puts prms.inspect
    prms
  end
  
  def displayLink?(linkParams, entry)
    test = linkParams[3]
    test.nil? || test == true || entry.send(test)
  end
  
  def actionLink(linkParams, entry)
    return unless displayLink? linkParams, entry
    link_to linkParams[0], 
            child_group_params(local_group_key, entry.id, params[:page], 
              {:controller => linkParams[1], 
               :action => linkParams[2]})
  end

  def newLabel
    neu = case modelClass.article
            when 'Der' then 'Neuer'
            when 'Die' then 'Neue'
            when 'Das' then 'Neues'
            end
    neu + ' ' + modelClass.label
  end
  
  def groupLabel
    "von #{group.label}" if group
  end

  def genericPath
    'manage'
  end
     
end