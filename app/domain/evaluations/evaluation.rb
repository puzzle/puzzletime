# encoding: utf-8


# An Evaluation gives an overview of the worktimes reported to the system.
# It provides the sum of all Worktimes for a category, split up into several divisions.
# The detailed Worktimes may be inspected for the whole category or a certain division only.
# The worktime information may be constrained to certain periods of time.
#
# This class is abstract, subclasses generally override the class constants for customization.
class Evaluation

  class_attribute :division_method, :division_column, :division_join,
                  :sub_evaluation, :sub_work_items_eval, :label, :absences,
                  :total_details, :category_ref, :detail_columns, :detail_labels

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

  # The field of a division referencing the category entry in the database.
  # May be nil if not required for this Evaluation (default).
  self.category_ref     = nil

  # Columns to display in the detail view
  self.detail_columns   = [:work_date, :hours, :employee, :account, :billable, :booked,
                           :ticket, :description]

  # Table captions for detail columns
  self.detail_labels    = { work_date: 'Datum',
                            hours: 'Stunden',
                            times: 'Zeiten',
                            employee: 'Wer',
                            account: 'Projekt',
                            billable: '$',
                            booked: '&beta;'.html_safe,
                            ticket: 'Ticket',
                            description: 'Bemerkungen' }


  attr_reader :category,             # category
              :division              # selected division for detail Evaluations, nil otherwise


  ############### Time Evaluation Functions ###############

  # Returns a list of all division objects for the represented category.
  # May be parameterized by a period. This is ignored by default.
  def divisions(period = nil)
    category.send(division_method).list
  end

  # The record identifier of the category, 0 if category is not an active record
  def category_id
  	 category.is_a?(Class) ? 0 : category.id
  end

  def sum_times_grouped(period)
    worktime_query(category, period).
      joins(division_join).
      group(division_column).
      sum(:hours)
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
    worktime_query(category, period).sum(:hours).to_f
  end

  # Returns a list of all Worktime entries for this Evaluation in the given period
  # of time.
  def times(period)
    worktime_query(division || category, period, division).
      order('work_date ASC, from_start_time, work_item_id, employee_id')
  end

  def worktime_query(receiver, period = nil, division = nil)
    query = receiver.worktimes.where(type: worktime_type).in_period(period)
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
  def division_supplement(user)
    []
  end

  def sub_work_items_evaluation(division)
    sub_work_items_eval if sub_work_items_eval && division.children?
  end

  # Returns whether this Evaluation is personally for the current user.
  # Default is false.
  def for?(user)
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

  def report?
    account_id && !absences?    # && employee_id
  end

  def employee_id
    nil
  end

  def account_id
    nil
  end

  # Returns a CSV String for all times in this Evaluation
  def csv_string(period)
    CSV.generate do |csv|
      csv << ['Datum', 'Stunden', 'Von Zeit', 'Bis Zeit', 'Reporttyp',
              'Verrechenbar', 'Mitarbeiter', 'Projekt', 'Ticket', 'Bemerkungen']
      times(period).each do |time|
        csv << [I18n.l(time.work_date),
                time.hours,
                (time.start_stop? ? I18n.l(time.from_start_time, format: :time) : ''),
                (time.start_stop? && time.to_end_time? ? I18n.l(time.to_end_time, format: :time) : ''),
                time.report_type,
                time.billable,
                time.employee.label,
                time.account.label_verbose,
                time.ticket,
                time.description]
      end
    end
  end

  protected

  # Initializes a new Evaluation with the given category.
  def initialize(category)
    @category = category
  end

  private

  def worktime_type
    absences? ? 'Absencetime' : 'Ordertime'
  end

  def detail_label(item)
    return '' if item.nil? || item.kind_of?(Class)
    item.class.model_name.human + ': ' + item.label
  end

  def class_category?
    category.kind_of? Class
  end

end
