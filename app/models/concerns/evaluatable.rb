# encoding: utf-8

# A Module that provides the funcionality for a model object to be evaluated.
#
# A class mixin Evaluatable has to provide a has_many relation for worktimes.
# See Evaluation for further details.
module Evaluatable

  include Comparable
  include Conditioner

  # The displayed label of this object.
  def label
    to_s
  end

  # A more complete label, defaults to the normal label method.
  def label_verbose
    label
  end

  # A tooltip to display in a list
  def tooltip
    nil
  end

  # Finds all Worktimes related to this object in a given period.
  def find_worktimes(evaluation, period = nil, category_ref = false, options = {})
    options = conditions_for(evaluation, period, category_ref, options)
    options[:order] ||= 'work_date ASC, from_start_time, project_id, employee_id'
    worktimes.where(options[:conditions]).
              reorder(options[:order]).
              joins(options[:joins]).
              includes(options[:include]).
              references(options[:include])
  end

  # Sums all worktimes related to this object in a given period.
  def sum_worktime(evaluation, period = nil, category_ref = false, options = {})
    options = conditions_for(evaluation, period, category_ref, options)
    worktimes.where(options[:conditions]).
              joins(options[:joins]).
              sum(:hours).to_f
  end

  def sum_grouped_worktimes(evaluation, period = nil)
    options = conditions_for(evaluation, period)
    worktimes.where(options[:conditions]).
              joins(evaluation.division_join).
              group(evaluation.division_column).
              sum(:hours)
  end

  # Counts the number of worktimes related to this object in a given period.
  def count_worktimes(evaluation, period = nil, category_ref = false, options = {})
    options = conditions_for(evaluation, period, category_ref, options)
    worktimes.where(options[:conditions]).
              joins(options[:joins]).
              count
  end

  # Raises an Exception if this object has related Worktimes.
  # This method is a callback for :before_delete.
  def protect_worktimes
    fail 'Diesem Eintrag sind Arbeitszeiten zugeteilt. Er kann nicht entfernt werden.' unless worktimes.empty?
  end

  def <=>(other)
    return super(other) if self.kind_of? Class
    label_verbose <=> other.label_verbose
  end

  private

  def conditions_for(evaluation, period = nil, category_ref = false, options = {})
    options = clone_options(options)
    append_conditions(options[:conditions], ["type = '" + (evaluation.absences? ? 'Absencetime' : 'Projecttime') + "'"])
    append_conditions(options[:conditions], ['work_date BETWEEN ? AND ?', period.startDate, period.endDate]) if period
    append_conditions(options[:conditions], ["? = #{evaluation.category_ref}", evaluation.category_id]) if category_ref
    options
  end

end
