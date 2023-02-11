# frozen_string_literal: true

#  Copyright (c) 2006-2019, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class Presenters::LogPresenter
  attr_accessor :version
  attr_reader :employee, :params, :view

  def initialize(employee, params = nil, view = nil)
    @employee = employee
    @params   = params
    @view     = view
  end

  def versions
    @versions ||=
      PaperTrail::Version.where(employee_id: employee.id)
      .or(legacy_employee_log)
      .or(legacy_employment_log)
      .reorder('created_at DESC, id DESC')
      .includes(:item)
      .page(params[:page])
  end

  def present_author(versions)
    employee = Employee.find_by(id: versions.first.version_author)
    yield employee.to_s if employee
  end

  def present_changes(versions)
    versions.each do |version|
      yield title_for(version), changes_for(version)
    end
  end

  def title_for(version)
    model = version.item_type.parameterize
    return send("title_for_#{model}", version) if respond_to?("title_for_#{model}")

    event = version.event
    I18n.t("version.model.#{event}.#{model}", id: version.item_id)
  end

  def title_for_employmentrolesemployment(version)
    entry_class = version.item_type.constantize
    entry = entry_class.find_by(id: version.item_id) || version.object && entry_class.new(version.object_deserialized)
    role = entry&.employment_role || '(deleted)'
    I18n.t("version.model.#{version.event}.employmentrolesemployment", role: role, employment_id: entry&.employment_id)
  end

  def changes_for(version)
    version.changeset.collect do |attr, changes|
      next if changes.all?(&:blank?)

      attribute_change(version.item_type, attr, changes)
    end
  end

  def attribute_change(item_type, attr, changes)
    from, to = changes
    key = attribute_key(from, to)

    if attr == 'committed_worktimes_at'
      from = I18n.l(from, format: :month) if from
      to   = I18n.l(to,   format: :month) if to
    end

    I18n.t("version.attribute_change.#{key}", **attribute_args(item_type, attr, from, to))
  end

  private

  def legacy_employee_log
    PaperTrail::Version.where(
      item_id: employee.id,
      item_type: Employee.sti_name,
      employee_id: nil
    )
  end

  def legacy_employment_log
    PaperTrail::Version.where(employee_id: nil).where(legacy_employment_query)
  end

  def legacy_employment_query
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

  def attribute_args(item_type, attr, from, to)
    item_class = item_type.constantize
    attr_s = attr.to_s
    if item_class.defined_enums[attr_s]
      to = item_class.human_attribute_name([attr_s.pluralize, to].join('.'))
    end

    association = attr.gsub(/_id\z/, '')
    if reflection = item_class.reflect_on_association(association)
      from = resolve_association(reflection, from)
      to   = resolve_association(reflection, to)
    end

    {
      attr: item_class.human_attribute_name(attr),
      model_ref: I18n.t("version.model_reference.#{item_class.name.parameterize}"),
      from: from,
      to: to
    }
  end

  def resolve_association(reflection, id)
    reflection.class_name.constantize.find_by(id: id) || id
  end
end
