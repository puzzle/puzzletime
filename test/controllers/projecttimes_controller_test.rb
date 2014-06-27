# encoding: UTF-8
require 'test_helper'

class ProjecttimesControllerTest < ActionController::TestCase

  setup :login

  def test_new
    get :new
    assert_response :success
    assert_template 'new'
    assert_match /Auftragszeit erfassen/, @response.body
    assert_not_nil assigns(:worktime)
  end

  def test_new_with_template
    template = worktimes(:wt_mw_puzzletime)
    template.update_attributes(ticket: "123", description: "desc")

    get :new, template: template.id
    assert_equal template.project, assigns(:worktime).project
    assert_equal "123", assigns(:worktime).ticket
    assert_equal "desc", assigns(:worktime).description
  end

  def test_show
    worktime = worktimes(:wt_pz_allgemein)
    get :show, id: worktime.id
    assert_redirected_to action: 'index', week_date: worktime.work_date
  end

  def test_create_hours_day_type
    work_date = Date.today-7
    post :create, projecttime: { account_id: Project.first,
                                 work_date: work_date,
                                 ticket: "#1",
                                 description: "desc",
                                 hours: "5:30"
                                 }
    assert_redirected_to action: 'index', week_date: work_date
    assert flash[:alert].blank?
    assert_match /Projektzeit.*erfolgreich erstellt/, flash[:notice]
    assert_equal HoursDayType::INSTANCE, Projecttime.last.report_type
    assert_equal "#1", Projecttime.last.ticket
    assert_equal 5.5, Projecttime.last.hours
    assert_equal work_date, Projecttime.last.work_date
    assert_equal employees(:mark), Projecttime.last.employee # logged in user
  end

  def test_create_start_stop_type
    work_date = Date.today + 10
    post :create, projecttime: { account_id: Project.first,
                                 work_date: work_date,
                                 from_start_time: "8:00",
                                 to_end_time: "10:15"
                                 }
    assert_redirected_to action: 'index', week_date: work_date
    assert flash[:alert].blank?
    assert_match /Projektzeit.*erfolgreich erstellt/, flash[:notice]
    assert_equal StartStopType::INSTANCE, Projecttime.last.report_type
    assert_equal "08:00", Projecttime.last.from_start_time.strftime("%H:%M")
    assert_equal "10:15", Projecttime.last.to_end_time.strftime("%H:%M")
    assert_equal 2.25, Projecttime.last.hours
  end

  def test_create_with_missing_start_time
    work_date = Date.today + 10
    post :create, projecttime: { account_id: Project.first,
                                 work_date: work_date,
                                 to_end_time: "10:15"
                                 }
    assert_match /Anfangszeit ist ungültig/, @response.body
  end

  def test_update
    worktime = worktimes(:wt_mw_puzzletime)
    put :update, id: worktime, projecttime: { hours: "1:30" }

    worktime.reload
    assert_redirected_to action: 'index', week_date: worktime.work_date
    assert flash[:alert].blank?
    assert_match /Projektzeit.*aktualisiert/, flash[:notice]
    assert_equal HoursDayType::INSTANCE, worktime.report_type
    assert_nil worktime.from_start_time
    assert_nil worktime.to_end_time
    assert_equal 1.5, worktime.hours
  end

end
