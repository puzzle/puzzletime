# encoding: utf-8

# TODO: remove unused
module ManageHelper

  def link_params(prms = {})
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

  def display_link?(link_params, entry)
    test = link_params[3]
    test.nil? || test == true || entry.send(test)
  end

  def action_link_old(link_params, entry)
    return unless display_link? link_params, entry
    link_to link_params[0],
            child_group_params(local_group_key, entry.id, params[:page],
                               controller: link_params[1],
                               action: link_params[2])
  end

  def of_group_label
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
