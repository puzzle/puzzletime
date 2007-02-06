
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
    value = entry.send(attribute)
    case modelClass.columnType(attribute)
      when :date then td format_date(value), true
      when :float then td number_with_precision( value, 2 ), true
      when :integer then td value, true
      when :boolean then td(value ? 'ja' : 'nein', false)
      else td value, false
      end
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
  
  def groupLink
    if group
      '| ' + (link_to "&Uuml;bersicht #{group.class.labelPlural}",
                    :controller => group.class.to_s.downcase,
                    :action => 'list',
                    :page => params[:group_page] )
    end             
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
  
  def renderManage(options)
    if actionName = options[:action]
      options[:action] = "manage/#{actionName}" if absent?(actionName)
    elsif partial = options[:partial]
      options[:partial] = "manage/#{partial}" if absent?(partial, '_')
    end    
    render options
  end
  
private

  def td(value, alignRight)
    align = alignRight ? ' align="right"' : ''
    "<td#{align}>#{value}</td>"
  end
  
  def absent?(template, partial = '')
    ! template_exists?("#{controller.class.controller_path}/#{partial}#{template}", :rhtml)
  end
    
end