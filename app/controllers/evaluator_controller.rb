# encoding: utf-8

class EvaluatorController < ApplicationController

  # Checks if employee came from login or from direct url.
  before_action :authorize, only: [:clients, :employees, :overtime,
                                   :clientProjects, :employeeProjects, :employeeAbsences,
                                   :export_capacity_csv, :export_extended_capacity_csv, :export_ma_overview]
  before_action :set_period

  helper_method :user_view?

  def index
    overview
  end

  def overview
    set_evaluation
    set_navigation_levels
    @notifications = UserNotification.list_during(@period)
    render action: (user_view? ? 'user_overview' : 'overview')
  end

  def details
    redirect_to action: 'absencedetails' if params[:evaluation] == 'absencedetails'
    set_evaluation
    set_navigation_levels
    set_evaluation_details
    paginate_times
  end

  def absencedetails
    session[:evalLevels] = []
    params[:evaluation] = 'absencedetails'
    set_evaluation
    @period ||= Period.coming_month Date.today, 'Kommender Monat'
    @notifications = UserNotification.list_during(@period)
    paginate_times
  end

  def weekly
    redirect_to controller: 'graph', action: 'weekly'
  end

  def all_absences
    redirect_to controller: 'graph', action: 'all_absences'
  end

  def employee_planning
    redirect_to controller: 'plannings', action: 'employee_planning', employee_id: params[:category_id]
  end

  def employees_planning
    redirect_to controller: 'plannings', action: 'employees_planning'
  end

  def my_planning
    redirect_to controller: 'plannings', action: 'my_planning'
  end

  def project_planning
    redirect_to controller: 'plannings', action: 'project_planning'
  end

  def department_planning
    redirect_to controller: 'plannings', action: 'department_planning', department_id: params[:category_id]
  end

  def company_planning
    redirect_to controller: 'plannings', action: 'company_planning'
  end


  ########################  DETAIL ACTIONS  #########################

  def compose_report
    set_evaluation
    set_evaluation_details
  end

  def report
    set_evaluation
    set_evaluation_details
    options = params[:only_billable] ? { conditions: ["worktimes.billable = 't'"] } : {}
    @times = @evaluation.times(@period, options)
    @tckt_view = params[:combine_on] && (params[:combine] == 'ticket' || params[:combine] == 'ticket_employee')
    combine_times if params[:combine_on] && params[:combine] == 'time'
    combine_tickets if @tckt_view
    render layout: false
  end

  def export_csv
    set_evaluation
    set_evaluation_details
    filename = 'puzzletime_' + csv_label(@evaluation.category) + '-' +
               csv_label(@evaluation.division) + '.csv'
    set_export_header(filename)
    send_data(@evaluation.csv_string(@period),
              type: 'text/csv; charset=utf-8; header=present',
              filename: filename)
  end

  def book_all
    set_evaluation
    set_evaluation_details
    @evaluation.times(@period).each do |worktime|
      # worktime cannot be directly updated because it's loaded with :joins
      Worktime.update worktime.id, booked: 1
    end
    flash[:notice] = 'Alle Arbeitszeiten '
    flash[:notice] += "von #{Employee.find(@evaluation.employee_id).label} " if @evaluation.employee_id
    flash[:notice] += "für #{Project.find(@evaluation.account_id).label_verbose}" \
                     "#{ ' während dem ' + @period.to_s if @period} wurden verbucht."
    redirect_to params.merge(action: 'details')
  end

  ######################  OVERVIEW ACTIONS  #####################3

  def complete_project
    project = Project.find params[:project_id]
    memberships = @user.projectmemberships.where('project_id = ?', params[:project_id]).first
    if memberships.nil?
      # no direct membership - complete parent project
      memberships = @user.projectmemberships.where('? = ANY (projects.path_ids)', params[:project_id])
    else
      memberships = [memberships]
    end
    memberships.each do |pm|
      pm.update_attributes(last_completed: Date.today)
    end
    flash[:notice] = 'Das Datum der kompletten Erfassung aller Zeiten ' \
                     "für das Projekt #{project.label_verbose} wurde aktualisiert."
    redirect_to params[:back_url]
  end

  def complete_all
    @user.projectmemberships.where(active: true).update_all(last_completed: Date.today)
    flash[:notice] = 'Das Datum der kompletten Erfassung aller Zeiten wurde für alle Projekte aktualisiert.'
    redirect_to params[:back_url]
  end

  def export_capacity_csv
    if @period
      send_csv(CapacityReport.new(@period))
    else
      flash[:notice] = 'Bitte wählen Sie eine Zeitspanne für die detaillierte Auslastung.'
      redirect_to request.env['HTTP_REFERER'].present? ? :back : root_path
    end
  end

  def export_extended_capacity_csv
    if @period
      send_csv(ExtendedCapacityReport.new(@period))
    else
      flash[:notice] = 'Bitte wählen Sie eine Zeitspanne für die Auslastung.'
      redirect_to request.env['HTTP_REFERER'].present? ? :back : root_path
    end
  end

  def export_ma_overview
    @period ||= Period.current_year
    # render :action => :export_ma_overview, :layout => false
  end

  ########################  PERIOD ACTIONS  #########################

  def select_period
    @period = Period.new if @period.nil?
  end

  def current_period
    session[:period] = nil
    redirect_to params[:back_url]
  end

  def change_period
    if params[:shortcut]
      @period = Period.parse(params[:shortcut])
    else
      @period = Period.retrieve(params[:period][:startDate],
                                params[:period][:endDate],
                                params[:period][:label])
    end
    fail ArgumentError, 'Start Datum nach End Datum' if @period.negative?
    session[:period] = [@period.startDate.to_s, @period.endDate.to_s,  @period.label]
     # redirect_to_overview
    redirect_to params[:back_url]
  rescue ArgumentError => ex        # ArgumentError from Period.new or if period.negative?
    flash[:notice] = "Ungültige Zeitspanne: #{ex}"
    render action: 'select_period'
  end


  # Dispatches evaluation names used as actions
  def action_missing(action, *args)
    params[:evaluation] = action.to_s
    overview
  end

  def user_view?
    params[:evaluation] =~ /^user/
  end

  private

  def set_evaluation
    params[:evaluation] ||= 'userprojects'
    @evaluation = case params[:evaluation].downcase
        when 'managed' then ManagedProjectsEval.new(@user)
        when 'absencedetails' then AbsenceDetailsEval.new
        when 'userprojects' then EmployeeProjectsEval.new(@user.id, @period)
        when "employeesubprojects#{@user.id}", 'usersubprojects' then
          params[:evaluation] = 'usersubprojects'
          EmployeeSubProjectsEval.new(params[:category_id], @user.id)
        when 'userabsences' then EmployeeAbsencesEval.new(@user.id)
        when 'subprojects' then SubProjectsEval.new(params[:category_id])
        when 'projectemployees' then ProjectEmployeesEval.new(params[:category_id], @period)
        else nil
    end
    if @user.management && @evaluation.nil?
      @evaluation = case params[:evaluation].downcase
        when 'clients' then ClientsEval.new
        when 'employees' then EmployeesEval.new
        when 'departments' then DepartmentsEval.new
        when 'clientprojects' then ClientProjectsEval.new(params[:category_id])
        when 'employeeprojects' then EmployeeProjectsEval.new(params[:category_id], @period)
        when /employeesubprojects(\d+)/ then EmployeeSubProjectsEval.new(params[:category_id], Regexp.last_match[1])
        when 'departmentprojects' then DepartmentProjectsEval.new(params[:category_id])
        when 'absences' then AbsencesEval.new
        when 'employeeabsences' then EmployeeAbsencesEval.new(params[:category_id])
        else nil
      end
    end
    if @evaluation.nil?
      @evaluation = EmployeeProjectsEval.new(@user.id, false)
    end
  end

  def set_evaluation_details
    @evaluation.set_division_id(params[:division_id])
    if params[:start_date]
      @period = params[:start_date] == '0' ? nil :
                   Period.retrieve(params[:start_date], params[:end_date])
    end
  end

  def set_navigation_levels
    # set session evaluation levels
    session[:evalLevels] = [] if params[:clear] || session[:evalLevels].nil?
    levels = session[:evalLevels]
    current = [params[:evaluation], @evaluation.category_id, @evaluation.title]
    levels.pop while levels.any? { |level| pop_level? level, current }
    levels.push current
  end

  def pop_level?(level, current)
    pop = level[0] == current[0]
    if level[0] =~ /(employee|user)?subprojects(\d*)/
      pop &&= level[1] == current[1]
    end
    pop
  end

  def paginate_times
    @times = @evaluation.times(@period).page(params[:page])
  end

  def set_export_header(filename)
    if request.env['HTTP_USER_AGENT'] =~ /msie/i
      headers['Pragma'] = 'public'
      headers['Content-type'] = 'text/plain'
      headers['Cache-Control'] = 'no-cache, must-revalidate, post-check=0, pre-check=0'
      headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
      headers['Expires'] = '0'
    else
      headers['Content-Type'] ||= 'text/csv'
      headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
    end
  end

  def redirect_to_overview
    redirect_to action: params[:evaluation],
                category_id: params[:category_id]
  end

  def combine_times
    combined_map = {}
    combined_times = []
    @times.each do |time|
      if time.report_type.kind_of?(StartStopType) && params[:start_stop]
        combined_times.push time
      else
        key = "#{time.date_string}$#{time.employee.shortname}"
        if combined_map.include?(key)
          combined_map[key].hours += time.hours
          if time.description
            if combined_map[key].description
              combined_map[key].description += "\n" + time.description
            else
              combined_map[key].description = time.description
            end
          end
        else
          combined_map[key] = time
          combined_times.push time
        end
      end
    end
    @times = combined_times
  end

  # builds a hash which contains all information needed by the report grouped by ticket
  def combine_tickets
    ticket_groups = @times.group_by(&:ticket)
    # remove ticket group with key nil and '' (empty string)
    ticket_groups.delete(nil)
    ticket_groups.delete('')

    @tickets = {}

    ticket_groups.each do |ticket, worktimes|
      if @tickets[ticket].nil?
        @tickets[ticket] = { n_entries: 0,
                             sum: 0,
                             employees: Hash.new,
                             date: Array.new(2),
                             descriptions: Array.new }
      end

      for t in worktimes
        @tickets[ticket][:n_entries] += 1
        @tickets[ticket][:sum] += t.hours

        # employees involved in this ticket
        if @tickets[ticket][:employees][t.employee.shortname].nil?
          @tickets[ticket][:employees][t.employee.shortname] = [t.hours, [t.description]]
        else
          @tickets[ticket][:employees][t.employee.shortname][0] += t.hours
          @tickets[ticket][:employees][t.employee.shortname][1] << t.description
        end

        # date range of this ticket
        if @tickets[ticket][:date][0].nil?
          @tickets[ticket][:date][0] = t.work_date
        else
          if t.work_date < @tickets[ticket][:date][0]
            @tickets[ticket][:date][0] = t.work_date
          end
        end

        if @tickets[ticket][:date][1].nil?
          @tickets[ticket][:date][1] = t.work_date
        else
          if t.work_date > @tickets[ticket][:date][1]
            @tickets[ticket][:date][1] = t.work_date
          end
        end

        @tickets[ticket][:descriptions] << "\"" + t.description + "\""
      end

    end
    # p "Grouped object: #{ticket_groups}"
  end

  def send_csv(csv_report)
    set_export_header(csv_report.filename)
    send_data(csv_report.to_csv, type: 'text/csv; charset=utf-8; header=present', filename: csv_report.filename)
  end

  def csv_label(item)
    item.nil? || !item.respond_to?(:label) ? '' :
      item.label.downcase.gsub(/[^0-9a-z]/, '_')
  end

end
