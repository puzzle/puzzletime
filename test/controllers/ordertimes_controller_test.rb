# encoding: UTF-8
require 'test_helper'

class OrdertimesControllerTest < ActionController::TestCase

  setup :login

  def test_new
    get :new
    assert_response :success
    assert_template 'new'
    assert_match(/Arbeitszeit erfassen/, @response.body)
    assert_no_match(/Mitarbeiter/, @response.body)
    assert_not_nil assigns(:worktime)
  end

  def test_new_with_template
    template = worktimes(:wt_mw_puzzletime)
    template.update_attributes!(ticket: '123', description: 'desc')

    get :new, template: template.id
    assert_equal template.work_item, assigns(:worktime).work_item
    assert_equal '123', assigns(:worktime).ticket
    assert_equal 'desc', assigns(:worktime).description
    assert assigns(:worktime).billable?
  end

  def test_new_without_billable_template
    template = worktimes(:wt_mw_puzzletime)
    template.update_attributes(billable: false)
    get :new, template: template.id
    assert !assigns(:worktime).billable?
  end

  def test_new_other
    get :new, other: 1
    assert_template 'new'
    assert_match(/Mitarbeiter/, @response.body)
    assert_nil assigns(:worktime).employee
  end

  def test_show
    worktime = worktimes(:wt_pz_allgemein)
    get :show, id: worktime.id
    assert_redirected_to action: 'index', week_date: worktime.work_date
  end

  def test_create_hours_day_type
    work_date = Date.today - 7
    post :create, ordertime: { account_id: work_items(:puzzletime),
                               work_date: work_date,
                               ticket: '#1',
                               description: 'desc',
                               hours: '00:45'}
    assert_redirected_to action: 'index', week_date: work_date
    assert flash[:alert].blank?
    assert_match(/Zeit.*erfolgreich erstellt/, flash[:notice])
    assert_equal work_items(:puzzletime), Ordertime.last.work_item
    assert_equal HoursDayType::INSTANCE, Ordertime.last.report_type
    assert_equal '#1', Ordertime.last.ticket
    assert_equal 0.75, Ordertime.last.hours
    assert_equal work_date, Ordertime.last.work_date
    assert_equal employees(:mark), Ordertime.last.employee # logged in user
  end

  def test_create_start_stop_type
    work_date = Date.today + 10
    post :create, ordertime: { account_id: work_items(:allgemein),
                               work_date: work_date,
                               from_start_time: '8:00',
                               to_end_time: '10:15' }
    assert_redirected_to action: 'index', week_date: work_date
    assert flash[:alert].blank?
    assert_match(/Zeit.*erfolgreich erstellt/, flash[:notice])
    assert_equal StartStopType::INSTANCE, Ordertime.last.report_type
    assert_equal '08:00', Ordertime.last.from_start_time.strftime('%H:%M')
    assert_equal '10:15', Ordertime.last.to_end_time.strftime('%H:%M')
    assert_equal 2.25, Ordertime.last.hours
  end

  def test_create_with_missing_start_time
    work_date = Date.today + 10
    post :create, ordertime: { account_id: work_items(:allgemein),
                               work_date: work_date,
                               to_end_time: '10:15' }
    assert_match(/Anfangszeit ist ungültig/, @response.body)
  end

  def test_create_other
    post :create, ordertime: { account_id: work_items(:allgemein),
                               work_date: Date.today,
                               hours: '5:30',
                               employee_id: employees(:lucien) }
    assert_equal employees(:lucien), Ordertime.last.employee
  end

  def test_create_other_without_permission
    login_as(:lucien)
    post :create, ordertime: { account_id: work_items(:allgemein),
                               work_date: Date.today,
                               hours: '5:30',
                               employee_id: employees(:mark) }
    assert_equal employees(:lucien), Ordertime.last.employee # assigns the projettime to himself
  end

  def test_update
    worktime = worktimes(:wt_mw_puzzletime)
    put :update, id: worktime, ordertime: { hours: '1:30' }

    worktime.reload
    assert_redirected_to action: 'index', week_date: worktime.work_date
    assert flash[:alert].blank?
    assert_match(/Zeit.*aktualisiert/, flash[:notice])
    assert_equal HoursDayType::INSTANCE, worktime.report_type
    assert_nil worktime.from_start_time
    assert_nil worktime.to_end_time
    assert_equal 1.5, worktime.hours
  end

  def test_split
    worktime = worktimes(:wt_pz_allgemein)
    session[:split] = WorktimeEdit.new(worktime)
    get :split
    assert_template 'split'
  end

  def test_incomplete_split
    worktime = worktimes(:wt_pz_allgemein)
    put :update, id: worktime, ordertime: { hours: '0:30', employee_id: employees(:pascal) }
    assert_redirected_to action: 'split'
    assert_not_nil assigns(:split)
  end

  def test_complete_split
    worktime = worktimes(:wt_pz_allgemein)
    put :update, id: worktime, ordertime: { hours: '1:00', employee_id: employees(:pascal) }
    assert_not_nil assigns(:split)
    assert_match(/Alle Arbeitszeiten wurden erfasst/, flash[:notice])
    worktime.reload
    assert_equal employees(:pascal), worktime.employee
  end

  def test_create_completing_part
    worktime = worktimes(:wt_pz_allgemein)
    split = WorktimeEdit.new(worktime)
    worktime.hours = 0.5
    split.add_worktime(worktime)
    session[:split] = split
    put :create_part,
        id: worktime,
        ordertime: { hours: '0:30',
                     employee_id: employees(:pascal),
                     work_date: worktime.work_date,
                     account_id: worktime.work_item_id }
    assert_equal [], assigns(:worktime).errors.full_messages
    assert_match(/Alle Arbeitszeiten wurden erfasst/, flash[:notice])
  end

  def test_create_incomplete_part
    worktime = worktimes(:wt_pz_allgemein)
    split = WorktimeEdit.new(worktime)
    worktime.hours = 0.5
    split.add_worktime(worktime)
    session[:split] = split
    put :create_part,
        id: worktime,
        ordertime: { hours: '0:24',
                     employee_id: employees(:pascal),
                     work_date: worktime.work_date,
                     account_id: worktime.work_item_id }
    assert_equal [], assigns(:worktime).errors.full_messages
    assert_in_delta 0.1, assigns(:split).worktime_template.hours
    assert_redirected_to action: 'split'
  end

  def test_create_invalid_part
    worktime = worktimes(:wt_pz_allgemein)
    split = WorktimeEdit.new(worktime)
    worktime.hours = 0.5
    split.add_worktime(worktime)
    session[:split] = split
    put :create_part,
        id: worktime,
        ordertime: { hours: '0:24',
                     employee_id: employees(:mark),
                     work_date: worktime.work_date + 1,
                     account_id: worktime.work_item_id }
    assert_template 'split'
    assert_match(/kann nicht geändert werden/, assigns(:worktime).errors[:work_date].first)
  end

  def test_destroy
    worktime = worktimes(:wt_mw_puzzletime)
    work_date = worktime.work_date
    delete :destroy, id: worktime
    assert_redirected_to action: 'index', week_date: work_date
    assert_nil Ordertime.find_by_id(worktime.id)
  end

end
