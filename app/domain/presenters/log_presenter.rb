# frozen_string_literal: true

#  Copyright (c) 2006-2019, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class LogPresenter
  attr_accessor :version
  attr_reader :employee, :params, :view

  def initialize(employee, params = nil, view = nil)
    @employee = employee
    @params   = params
    @view     = view
  end

  def versions
    @versions ||=
      all_logs
      .reorder('created_at DESC, id DESC')
      .includes(:item)
      .page(params[:page])
  end

  def table_items
    versions.group_by(&:created_at).each
  end

  def author?
    author.present?
  end

  def author
    if version.version_author.present?
      employee = Employee.where(id: version.version_author).first
      employee.to_s if employee.present?
    end
  end

  def title
    model = version.item_type.parameterize
    event = version.event
    view.t("version.model.#{event}.#{model}", id: version.item_id)
  end

  def attribute_change(attr, from, to)
    key = attribute_key(from, to)
    view.t("version.attribute_change.#{key}", attribute_args(attr, from, to))
  end

  def all_changes
    view.safe_join(version.changeset) do |attr, (from, to)|
      unless from.blank? && to.blank?
        view.content_tag(:div, attribute_change(attr, from, to))
      end
    end
  end


  private

  def item_class
    version.item_type.constantize
  end

  def all_logs
    employee_log
      .or(employment_log)
  end

  def employee_log
    PaperTrail::Version.where(
      item_id: employee.id,
      item_type: Employee.sti_name
    )
  end

  def employment_log
    PaperTrail::Version.where(employment_query)
  end

  def employment_query
    id = employee.id

    # find created, updated and destroyed models
    ["- \n- #{id}\n", "- #{id}\n- #{id}\n", "- #{id}\n- \n"]
      .collect { |s| "object_changes LIKE '%employee_id:\n#{s}%'" }
      .join(' OR ')
  end

  def attribute_key(from, to)
    if from.present? && to.present?
      'from_to'
    elsif from.present?
      'from'
    elsif to.present?
      'to'
    end
  end

  def attribute_args(attr, from, to)
    attr_s = attr.to_s
    if item_class.defined_enums[attr_s]
      to = item_class.human_attribute_name([attr_s.pluralize, to].join('.'))
    end

    association = attr.humanize.parameterize
    if item_class.reflect_on_association(association)
      from = resolve_association(association, from)
      to   = resolve_association(association, to)
    end

    {
      attr: item_class.human_attribute_name(attr),
      model_ref: view.t("version.model_reference.#{item_class.name.parameterize}"),
      from: from,
      to: to
    }
  end

  def resolve_association(association, id)
    association.classify.constantize.find_by(id: id) || id
  end

end
