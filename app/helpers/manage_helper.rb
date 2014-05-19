
module ManageHelper

  def inputField(field)
    case modelClass.columnType(field[0])
      when :date then date_calendar_field 'entry', field[0]
      when :boolean then check_box 'entry', field[0]
      when :float, :integer then text_field 'entry', field[0], size: 15
      when :text then text_area 'entry', field[0], rows: 5, cols: 30
      when :report_type then select 'entry', field[0],
                                    ReportType::INSTANCES.collect { |type| [type.name, type.key] },
                                    selected: @entry.send(field[0]).key
      else text_field 'entry', field[0], size: 30
      end
  end

  def dataField(entry, attribute)
    options = case modelClass.columnType(attribute)
                when :date, :float, :integer, :decimal then { align: :right }
                when :boolean then { align: :center }
                else {}
                end
    # "<td#{options}>#{h(formatColumn(attribute, entry.send(attribute), entry)).gsub("\n", '<br/>')}</td>"
    simple_format(formatColumn(attribute, entry.send(attribute), entry), options, wrapper_tag: :td)
  end

  def linkParams(prms = {})
    prms[:page]        ||= params[:page]
    prms[:groups]      ||= params[:groups]
    prms[:group_ids]   ||= params[:group_ids]
    prms[:group_pages] ||= params[:group_pages]
    prms
  end

  def child_group_params(key, id, page, prms = {})
    prms[:groups]      ||= append_param(:groups, key)
    prms[:group_ids]   ||= append_param(:group_ids, id)
    prms[:group_pages] ||= append_param(:group_pages, page ? page : 1)
    prms
  end

  def group_params(prms = {})
    prms[:page]        ||= last_param(:group_pages)
    prms[:groups]      ||= remove_last_param(:groups)
    prms[:group_ids]   ||= remove_last_param(:group_ids)
    prms[:group_pages] ||= remove_last_param(:group_pages)
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
                               controller: linkParams[1],
                               action: linkParams[2])
  end

  def newLabel
    neu = case modelClass.article
            when 'Der' then 'Neuer'
            when 'Die' then 'Neue'
            when 'Das' then 'Neues'
            end
    neu + ' ' + modelClass.label
  end

  def error_messages_for(entry)
    render 'shared/error_messages', object: entry
  end

  def groupLabel
    "von #{group.label}" if group
  end

  private

  def last_param(key)
    params[key].split('-').last if params[key]
  end

  def remove_last_param(key)
    if params[key]
      param_array = params[key].split('-')[0..-2]
      return param_array.join('-') unless param_array.empty?
    end
    nil
  end

  def append_param(key, value)
    params[key] ? "#{params[key]}-#{value}" : value
  end
end
