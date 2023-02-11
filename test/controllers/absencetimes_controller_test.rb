#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

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
    template.update(description: 'desc')

    get :new, params: { template: template.id }
    assert_equal template.absence, assigns(:worktime).absence
    assert_equal 'desc', assigns(:worktime).description
  end

  def test_show
    worktime = worktimes(:wt_pz_vacation)
    get :show, params: { id: worktime.id }
    assert_redirected_to action: 'index', week_date: worktime.work_date
  end

  def test_edit
    get :edit, params: { id: worktimes(:wt_mw_service) }
    assert_template 'edit'
    assert_match(/Absenz bearbeiten/, @response.body)
    assert_no_match(/Mehrwöchige/, @response.body)
  end

  def test_create_hours_day_type
    work_date = Time.zone.today - 7
    post :create, params: {
      absencetime: {
        absence_id: absences(:doctor),
        work_date: work_date,
        description: 'desc',
        hours: '2:45'
      }
    }
    assert_redirected_to action: 'index', week_date: work_date
    assert flash[:alert].blank?
    assert_match(/Absenz.*erfolgreich erstellt/, flash[:notice])
    assert_equal absences(:doctor), Absencetime.last.absence
    assert_equal ReportType::HoursDayType::INSTANCE, Absencetime.last.report_type
    assert_equal 'desc', Absencetime.last.description
    assert_equal 2.75, Absencetime.last.hours
    assert_equal work_date, Absencetime.last.work_date
    assert_equal employees(:mark), Absencetime.last.employee # logged in user
  end

  def test_create_start_stop_type
    work_date = Time.zone.today + 10
    post :create, params: {
      absencetime: {
        absence_id: absences(:vacation),
        work_date: work_date,
        from_start_time: '7:30',
        to_end_time: '12:00'
      }
    }
    assert_redirected_to action: 'index', week_date: work_date
    assert flash[:alert].blank?
    assert_match(/Absenz.*erfolgreich erstellt/, flash[:notice])
    assert_equal absences(:vacation), Absencetime.last.absence
    assert_equal ReportType::StartStopType::INSTANCE, Absencetime.last.report_type
    assert_equal '07:30', Absencetime.last.from_start_time.strftime('%H:%M')
    assert_equal '12:00', Absencetime.last.to_end_time.strftime('%H:%M')
    assert_equal 4.5, Absencetime.last.hours
  end

  def test_create_multiabsence
    login_as(:long_time_john)
    work_date = Date.new(2014, 7, 7) # no offical holidays in the next 3 weeks
    post :create, params: {
      absencetime: {
        absence_id: absences(:vacation),
        work_date: work_date,
        create_multi: 'true',
        duration: '3'
      }
    }
    assert_redirected_to action: 'index', week_date: work_date
    assert flash[:alert].blank?
    assert_match(/15 Absenzen wurden erfasst/, flash[:notice])
  end

  def test_create_other_multiabsence
    work_date = Date.new(2014, 7, 1)
    post :create, params: {
      absencetime: {
        absence_id: absences(:vacation),
        work_date: work_date,
        create_multi: 'true',
        duration: '2',
        employee_id: employees(:various_pedro)
      }
    }
    assert_redirected_to action: 'index', week_date: work_date
    assert flash[:alert].blank?
    assert_match(/10 Absenzen wurden erfasst/, flash[:notice])
  end

  def test_create_multiabsence_with_errors
    login_as(:long_time_john)
    work_date = Time.zone.today + 3
    post :create, params: {
      absencetime: {
        absence_id: absences(:vacation),
        work_date: work_date,
        create_multi: 'true',
        duration: '-3'
      }
    }
    assert_template 'new'
    assert_match(/Dauer muss grösser als 0 sein/, assigns(:worktime).errors.full_messages.join)
  end

  def test_update
    worktime = worktimes(:wt_mw_service)
    assert_equal ReportType::HoursDayType::INSTANCE, worktime.report_type
    put :update, params: { id: worktime, absencetime: { from_start_time: '8:15', to_end_time: '10:00' } }

    worktime.reload
    assert_redirected_to action: 'index', week_date: worktime.work_date
    assert flash[:alert].blank?
    assert_match(/Absenz.*aktualisiert/, flash[:notice])
    assert_equal ReportType::StartStopType::INSTANCE, worktime.report_type
    assert_equal '08:15', worktime.from_start_time.strftime('%H:%M')
    assert_equal '10:00', worktime.to_end_time.strftime('%H:%M')
    assert_equal 1.75, worktime.hours
  end

  def test_destroy
    worktime = worktimes(:wt_mw_service)
    work_date = worktime.work_date
    delete :destroy, params: { id: worktime }
    assert_redirected_to action: 'index', week_date: work_date
    assert_nil Absencetime.find_by_id(worktime.id)
  end

  test 'committed absencetimes may not be created by user' do
    e = employees(:pascal)
    e.update!(committed_worktimes_at: '2015-08-31')
    login_as(:pascal)
    post :create, params: {
      absencetime: {
        absence_id: absences(:vacation).id,
        work_date: '2015-08-31',
        hours: '2'
      }
    }
    assert_template('new')
    assert assigns(:worktime).errors[:work_date].present?
  end

  test 'uncommitted absencetimes may be created by user' do
    e = employees(:pascal)
    login_as(:pascal)
    post :create, params: {
      absencetime: {
        absence_id: absences(:vacation).id,
        work_date: '2015-08-31',
        hours: '2'
      }
    }

    assert flash[:notice].present?
  end

  test 'committed absencetimes may be created by manager' do
    e = employees(:pascal)
    e.update!(committed_worktimes_at: '2015-08-31')
    login_as(:mark)
    post :create, params: {
      absencetime: {
        absence_id: absences(:vacation).id,
        work_date: '2015-08-31',
        hours: '2',
        employee_id: e.id
      }
    }

    assert flash[:notice].present?
  end

  test 'committed absencetimes may not be updated by user' do
    e = employees(:pascal)
    t = Absencetime.create!(
      employee: e,
      work_date: '2015-08-31',
      hours: 2,
      report_type: 'absolute_day',
      absence: absences(:vacation)
    )

    e.update!(committed_worktimes_at: '2015-09-30')
    login_as(:pascal)
    assert_raises(CanCan::AccessDenied) do
      put :update, params: { id: t.id, absencetime: { hours: '3' } }
    end
  end

  test 'committed absencetimes may be updated by manager' do
    skip "currently it's not possible to edit a user's" \
         'absence time as manager see issue #15629'

    e = employees(:pascal)
    t = Absencetime.create!(
      employee: e,
      work_date: '2015-08-31',
      hours: 2,
      report_type: 'absolute_day',
      absence: absences(:vacation)
    )

    e.update!(committed_worktimes_at: '2015-09-30')
    login_as(:mark)
    patch :update, params: { id: t.id, absencetime: { description: 'bla bla' } }
    assert flash[:notice].present?
    assert_equal 'bla bla', t.reload.description
  end

  test 'committed absencetimes may not change work date forward by user' do
    e = employees(:pascal)
    t = Absencetime.create!(
      employee: e,
      work_date: '2015-08-31',
      hours: 2,
      report_type: 'absolute_day',
      absence: absences(:vacation)
    )
    e.update!(committed_worktimes_at: '2015-09-30')
    login_as(:pascal)
    assert_raises(CanCan::AccessDenied) do
      patch :update, params: { id: t.id, absencetime: { work_date: '2015-10-10' } }
    end
  end

  # test 'committed absencetimes may not change work date backward by user' do
  test '2' do
    e = employees(:pascal)
    t = Absencetime.create!(
      employee: e,
      work_date: '2015-10-10',
      hours: 2,
      report_type: 'absolute_day',
      absence: absences(:vacation)
    )
    e.update!(committed_worktimes_at: '2015-09-30')
    login_as(:pascal)

    patch :update, params: { id: t.id, absencetime: { work_date: '2015-08-31' } }
    assert_template('edit')
    assert assigns(:worktime).errors[:work_date].present?
  end

  test 'committed absencetimes may not be destroyed by user' do
    e = employees(:pascal)
    t = Absencetime.create!(
      employee: e,
      work_date: '2015-08-31',
      hours: 2,
      report_type: 'absolute_day',
      absence: absences(:vacation)
    )
    e.update!(committed_worktimes_at: '2015-09-30')
    login_as(:pascal)

    assert_raises(CanCan::AccessDenied) { delete :destroy, params: { id: t.id } }
  end

  def test_create_with_no_employment
    # half_year_maria 2006-07-01 - 2006-12-31
    work_date = '2017-07-24'

    login_as :half_year_maria

    post :create, params: {
      absencetime: {
        absence_id: absences(:vacation).id,
        work_date: work_date,
        hours: 8
      }
    }
    assert_redirected_to action: 'index', week_date: work_date
    assert flash[:alert].blank?
    assert_match(/Absenz.*erfolgreich erstellt/, flash[:notice])
    assert_match(/keine Anstellung/, flash[:warning])
  end

  def test_create_with_zero_percent_employment
    # half_year_maria 2006-07-01 - 2006-12-31
    work_date = '2017-07-24'

    Fabricate(:employment,
              employee: employees(:half_year_maria),
              percent: 0,
              start_date: '2017-01-01')

    login_as :half_year_maria

    post :create, params: {
      absencetime: {
        absence_id: absences(:vacation).id,
        work_date: work_date,
        hours: 8
      }
    }
    assert_redirected_to action: 'index', week_date: work_date
    assert flash[:alert].blank?
    assert_match(/Absenz.*erfolgreich erstellt/, flash[:notice])
    assert_match(/unbezahlter Urlaub/, flash[:warning])
  end
end
