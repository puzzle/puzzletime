# encoding: UTF-8
require 'test_helper'

class AbsencetimesControllerTest < ActionController::TestCase

  setup :login

  def test_new
    get :new
    assert_response :success
    assert_template 'new'
    assert_match(/Absenz erfassen/, @response.body)
    assert_match(/Mehrwöchige/, @response.body)
    assert_not_nil assigns(:worktime)
  end

  def test_new_with_template
    template = worktimes(:wt_pz_vacation)
    template.update_attributes(description: 'desc')

    get :new, template: template.id
    assert_equal template.absence, assigns(:worktime).absence
    assert_equal 'desc', assigns(:worktime).description
  end

  def test_show
    worktime = worktimes(:wt_pz_vacation)
    get :show, id: worktime.id
    assert_redirected_to action: 'index', week_date: worktime.work_date
  end

  def test_edit
    get :edit, id: worktimes(:wt_mw_service)
    assert_template 'edit'
    assert_match(/Absenz bearbeiten/, @response.body)
    assert_no_match(/Mehrwöchige/, @response.body)
  end

  def test_create_hours_day_type
    work_date = Date.today-7
    post :create, absencetime: { absence_id: absences(:doctor),
                                 work_date: work_date,
                                 description: 'desc',
                                 hours: '2:45'
                                 }
    assert_redirected_to action: 'index', week_date: work_date
    assert flash[:alert].blank?
    assert_match(/Absenz.*erfolgreich erstellt/, flash[:notice])
    assert_equal absences(:doctor), Absencetime.last.absence
    assert_equal HoursDayType::INSTANCE, Absencetime.last.report_type
    assert_equal 'desc', Absencetime.last.description
    assert_equal 2.75, Absencetime.last.hours
    assert_equal work_date, Absencetime.last.work_date
    assert_equal employees(:mark), Absencetime.last.employee # logged in user
  end

  def test_create_start_stop_type
    work_date = Date.today + 10
    post :create, absencetime: { absence_id: absences(:vacation),
                                 work_date: work_date,
                                 from_start_time: '7:30',
                                 to_end_time: '12:00'
                                 }
    assert_redirected_to action: 'index', week_date: work_date
    assert flash[:alert].blank?
    assert_match(/Absenz.*erfolgreich erstellt/, flash[:notice])
    assert_equal absences(:vacation), Absencetime.last.absence
    assert_equal StartStopType::INSTANCE, Absencetime.last.report_type
    assert_equal '07:30', Absencetime.last.from_start_time.strftime('%H:%M')
    assert_equal '12:00', Absencetime.last.to_end_time.strftime('%H:%M')
    assert_equal 4.5, Absencetime.last.hours
  end

  def test_create_multiabsence
    login_as(:long_time_john)
    work_date = Date.today + 3
    post :create, absencetime: { absence_id: absences(:vacation),
                                 work_date: work_date,
                                 create_multi: 'true',
                                 duration: '3'
                                 }
    assert_redirected_to action: 'index', week_date: work_date
    assert flash[:alert].blank?
    assert_match(/15 Absenzen wurden erfasst/, flash[:notice])
  end

  def test_create_other_multiabsence
    work_date = Date.today + 3
    post :create, absencetime: { absence_id: absences(:vacation),
                                 work_date: work_date,
                                 create_multi: 'true',
                                 duration: '2',
                                 employee_id: employees(:various_pedro)
                                 }
    assert_redirected_to action: 'index', week_date: work_date
    assert flash[:alert].blank?
    assert_match(/10 Absenzen wurden erfasst/, flash[:notice])
  end

  def test_create_multiabsence_with_errors
    login_as(:long_time_john)
    work_date = Date.today + 3
    post :create, absencetime: { absence_id: absences(:vacation),
                                 work_date: work_date,
                                 create_multi: 'true',
                                 duration: '-3'
                                 }
    assert_template 'new'
    assert_match(/Dauer muss grösser als 0 sein/, assigns(:worktime).errors.full_messages.join)
  end

  def test_update
    worktime = worktimes(:wt_mw_service)
    assert_equal HoursDayType::INSTANCE, worktime.report_type
    put :update, id: worktime, absencetime: { from_start_time: '8:15', to_end_time: '10:00' }

    worktime.reload
    assert_redirected_to action: 'index', week_date: worktime.work_date
    assert flash[:alert].blank?
    assert_match(/Absenz.*aktualisiert/, flash[:notice])
    assert_equal StartStopType::INSTANCE, worktime.report_type
    assert_equal '08:15', worktime.from_start_time.strftime('%H:%M')
    assert_equal '10:00', worktime.to_end_time.strftime('%H:%M')
    assert_equal 1.75, worktime.hours
  end

  def test_destroy
    worktime = worktimes(:wt_mw_service)
    work_date = worktime.work_date
    delete :destroy, id: worktime
    assert_redirected_to action: 'index', week_date: work_date
    assert_nil Absencetime.find_by_id(worktime.id)
  end

end
