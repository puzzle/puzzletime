# encoding: utf-8


# An Evaluation gives an overview of the worktimes reported to the system.
# It provides the sum of all Worktimes for a category, split up into several divisions.
# The detailed Worktimes may be inspected for the whole category or a certain division only.
# The worktime information may be constrained to certain periods of time.
#
# This class is abstract, subclasses generally override the class constants for customization.
class Evaluation
  class_attribute :division_method, :division_column, :division_join, :division_planning_join,
                  :sub_evaluation, :sub_work_items_eval, :label, :absences,
                  :total_details, :billable_hours, :planned_hours, :category_ref, :detail_columns,
                  :detail_labels

  # The method to send to the category object to retrieve a list of divisions.
  self.division_method   = :list

  # Next lower evaluation for divisions, which will be acting as the category there.
  self.sub_evaluation    = nil

  self.sub_work_items_eval = nil

  # Name of the evaluation to be displayed
  self.label             = ''

  # Whether this Evaluation is for absences or order times.
  self.absences          = false

  # Whether details for totals are possible.
  self.total_details     = true

  # Whether to show billing hours beside performed hours
  self.billable_hours = false

  # Whether to show planned hours and difference in separate columns
  self.planned_hours = false

  # The field of a division referencing the category entry in the database.
  # May be nil if not required for this Evaluation (default).
  self.category_ref     = nil

  # Columns to display in the detail view
  self.detail_columns   = [:work_date, :hours, :employee, :account, :billable,
                           :ticket, :description]

  # Table captions for detail columns
  self.detail_labels    = { work_date: 'Datum',
                            hours: 'Stunden',
                            times: 'Zeiten',
                            employee: 'Wer',
                            account: 'Projekt',
                            billable: '$',
                            ticket: 'Ticket',
                            description: 'Bemerkungen' }


  attr_reader :category,             # category
              :division              # selected division for detail Evaluations, nil otherwise


  ############### Time Evaluation Functions ###############

  # Returns a list of all division objects for the represented category.
  # May be parameterized by a period. This is ignored by default.
  def divisions(_period = nil)
    category.send(division_method).list
  end

  # The record identifier of the category, 0 if category is not an active record
  def category_id
    category.is_a?(Class) ? 0 : category.id
  end

  def sum_times_grouped(period)
    query = worktime_query(category, period).
            joins(division_join).
            group(division_column)
    query_time_sums(query, division_column)
  end

  # Sums all worktimes for a given period.
  # If a division is passed or set previously, their sum will be returned.
  # Otherwise the sum of all worktimes in the main category is returned.
  def sum_times(period, div = nil, scope = nil)
    worktime_query(div || division || category,
                   period,
                   div || division).
      merge(scope).
      sum(:hours).to_f
  end

  # Sums all worktimes for the category in a given period.
  def sum_total_times(period = nil)
    query = worktime_query(category, period)
    query_time_sums(query)
  end

  # Returns a list of all Worktime entries for this Evaluation in the given period
  # of time.
  def times(period)
    worktime_query(division || category, period, division).
      order('worktimes.work_date ASC, worktimes.from_start_time, ' \
            'worktimes.work_item_id, worktimes.employee_id')
  end

  def worktime_query(receiver, period = nil, division = nil)
    query = receiver.worktimes.where(type: worktime_type).in_period(period)
    query = query.where("? = #{category_ref}", category_id) if division && category_ref
    query
  end

  ############### Planning Evaluation Functions ###############

  def sum_plannings_grouped(period)
    query = planning_query(category).joins(division_planning_join).group(division_column)
    if division_column
      query_grouped_planning_sums(query, period, division_column)
    else
      query_planning_sums(query, period)
    end
  end

  def sum_total_plannings(period = nil)
    query_planning_sums(planning_query(category), period)
  end

  def planning_query(receiver, division = nil)
    query = receiver.plannings.
              joins(:work_item).
              joins('INNER JOIN accounting_posts ON accounting_posts.work_item_id = ANY (work_items.path_ids)')
    query = query.where("? = #{category_ref}", category_id) if division && category_ref
    query
  end

  ################ Methods for overview ##############

  # The title for this Evaluation
  def title
    label + (class_category? ? ' Übersicht' : ' von ' + category.label)
  end

  def worktime_name
    absences? ? Absencetime.label : Ordertime.label
  end

  # The header name of the division column to be displayed.
  # Returns the class name of the division objects.
  def division_header
    divs = divisions
    divs.respond_to?(:klass) ? divs.klass.model_name.human : ''
  end

  # Returns a two-dimensional Array with helper methods of the evaluator
  # to be called in the overview (_division.rhtml) for each division
  # and the according table headers. May be used for displaying additional
  # information or links to certain actions.
  # No methods are called by default.
  # See EmployeeWorkItemsEval for an example.
  def division_supplement(_user)
    []
  end

  def sub_work_items_evaluation(division)
    sub_work_items_eval if sub_work_items_eval && division.children?
  end

  def include_no_period_zero_totals
    !category.is_a?(Employee)
  end

  # Returns whether this Evaluation is personally for the current user.
  # Default is false.
  def for?(_user)
    false
  end

  def ==(other)
    self.class == other.class &&
      category == other.category
  end

  ################ Methods for detail view ##############

  # Sets the id of the division object used for the detailed view.
  # Default is nil, the worktimes of all divisions are provided.
  def set_division_id(division_id = nil)
    return if division_id.nil?
    container = class_category? ? category : divisions
    @division = container.find(division_id.to_i)
  end

  # Label for the represented category.
  def category_label
    detail_label(category)
  end

  # Label for the represented division, if any.
  def division_label
    detail_label(division)
  end

  def edit_link?(user)
    for?(user) || !absences?
  end

  def delete_link?(user)
    for? user
  end

  def action_links?(user)
    user.management || edit_link?(user) || delete_link?(user)
  end

  def report?
    account_id && !absences? # && employee_id
  end

  def employee_id
    nil
  end

  def account_id
    nil
  end

  private

  # Initializes a new Evaluation with the given category.
  def initialize(category)
    @category = category
  end

  def query_time_sums(query, group_by_column = nil)
    if billable_hours
      if group_by_column.present?
        query_grouped_time_sums(query, group_by_column)
      else
        result = query.pluck(*hours_and_billable_hours_columns).first
        { hours: result.first.to_f, billable_hours: result.second.to_f }
      end
    else
      result = query.sum(:hours)
      result.is_a?(Hash) ? result : result.to_f
    end
  end

  def query_grouped_time_sums(query, group_by_column)
    result = query.pluck(group_by_column, *hours_and_billable_hours_columns)
    result.each_with_object({}) do |e, h|
      h[e[0]] = { hours: e[1].to_f, billable_hours: e[2].to_f }
    end
  end

  def hours_and_billable_hours_columns
    ['SUM(worktimes.hours) AS sum_hours',
     'SUM(CASE WHEN worktimes.billable = TRUE ' \
         'THEN worktimes.hours ' \
         'ELSE 0 END) ' \
         'AS sum_billable_hours']
  end

  def query_planning_sums(query, period)
    { hours: 0, billable_hours: 0 }.tap do |result|
      WorkingCondition.each_period_of(:must_hours_per_day, period) do |p, hours|
        r = query.in_period(p).pluck(*plannings_and_billable_plannings_columns(hours)).first
        result[:hours] += r.first.to_f
        result[:billable_hours] += r.second.to_f
      end
    end
  end

  def query_grouped_planning_sums(query, period, group_by_column)
    {}.tap do |result|
      WorkingCondition.each_period_of(:must_hours_per_day, period) do |p, hours|
        r = query.in_period(p).pluck(group_by_column, *plannings_and_billable_plannings_columns(hours))
        r.each do |e|
          result[e[0]] ||= { hours: 0, billable_hours: 0 }
          result[e[0]][:hours] += e[1].to_f
          result[e[0]][:billable_hours] += e[2].to_f
        end
      end
    end
  end

  def plannings_and_billable_plannings_columns(must_hours)
    ["SUM(plannings.percent / 100.0 * #{must_hours.to_f}) AS sum_hours",
     'SUM(CASE WHEN accounting_posts.billable = TRUE ' \
         "THEN plannings.percent / 100.0 * #{must_hours.to_f} " \
         'ELSE 0 END) ' \
         'AS sum_billable_hours']
  end

  def worktime_type
    absences? ? 'Absencetime' : 'Ordertime'
  end

  def detail_label(item)
    return '' if item.nil? || item.is_a?(Class)
    item.class.model_name.human + ': ' + item.label
  end

  def class_category?
    category.is_a? Class
  end
end
