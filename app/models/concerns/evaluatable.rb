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
    name
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
  def findWorktimes(evaluation, period = nil, categoryRef = false, options = {})
    options = conditionsFor(evaluation, period, categoryRef, options)
    options[:order] ||= 'work_date ASC, from_start_time, project_id, employee_id'
    worktimes.where(options[:conditions]).
              reorder(options[:order]).
              joins(options[:joins]).
              includes(options[:include]).
              references(options[:include])
  end

  # Sums all worktimes related to this object in a given period.
  def sumWorktime(evaluation, period = nil, categoryRef = false, options = {})
    options = conditionsFor(evaluation, period, categoryRef, options)
    worktimes.where(options[:conditions]).
              joins(options[:joins]).
              sum(:hours).to_f
  end

  # Counts the number of worktimes related to this object in a given period.
  def countWorktimes(evaluation, period = nil, categoryRef = false, options = {})
    options = conditionsFor(evaluation, period, categoryRef, options)
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

  # TODO use locales
  def to_s_old
    label
  end

  private

  def conditionsFor(evaluation, period = nil, categoryRef = false, options = {})
    options = clone_options(options)
    append_conditions(options[:conditions], ["type = '" + (evaluation.absences? ? 'Absencetime' : 'Projecttime') + "'"])
    append_conditions(options[:conditions], ['work_date BETWEEN ? AND ?', period.startDate, period.endDate]) if period
    append_conditions(options[:conditions], ["? = #{evaluation.categoryRef}", evaluation.category_id]) if categoryRef
    options
  end

end
