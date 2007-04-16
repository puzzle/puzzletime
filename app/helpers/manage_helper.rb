
module ManageHelper

  def inputField(field)
    case modelClass.columnType(field[0])
      when :date then date_calendar_field 'entry', field[0], field[1]
      when :boolean then check_box 'entry', field[0]
      when :float, :integer then text_field 'entry', field[0], :size => 15
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
    prms[:group_id] ||= params[:group_id]
    prms[:page] ||= params[:page]
    prms[:group_page] ||= params[:group_page]
    prms
  end
  
  def actionLink(linkParams, entry)
    link_to linkParams[0], 
            :controller => linkParams[1], 
            :action => linkParams[2], 
            :group_id => entry.id,
            :group_page => params[:page]
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