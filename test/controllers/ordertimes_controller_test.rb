#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


require 'test_helper'

class OrdertimesControllerTest < ActionController::TestCase
  setup :login

  def roles_users
    {
      employee:    :pascal,
      responsible: :lucien,
      manager:     :mark
    }
  end

  def test_new
    login_as(:pascal)
    get :new
    assert_response :success
    assert_template 'new'
    assert_match(/Arbeitszeit erfassen/, @response.body)
    assert_not_nil assigns(:worktime)
  end

  def test_new_with_template
    template = worktimes(:wt_mw_puzzletime)
    template.update_attributes!(ticket: '123', description: 'desc')

    get :new, params: { template: template.id }
    assert_equal template.work_item, assigns(:worktime).work_item
    assert_equal '123', assigns(:worktime).ticket
    assert_equal 'desc', assigns(:worktime).description
    assert assigns(:worktime).billable?
  end

  def test_new_without_billable_template
    template = worktimes(:wt_mw_puzzletime)
    template.update_attributes(billable: false)
    get :new, params: { template: template.id }
    assert !assigns(:worktime).billable?
  end

  def test_new_other
    get :new, params: { other: 1 }
    assert_template 'new'
    assert_match(/Mitarbeiter/, @response.body)
    assert_nil assigns(:worktime).employee
  end

  def test_show
    worktime = worktimes(:wt_pz_allgemein)
    get :show, params: { id: worktime.id }
    assert_redirected_to action: 'index', week_date: worktime.work_date
  end

  def test_create_hours_day_type
    work_date = Time.zone.today - 7
    post :create, params: {
                               ordertime: { account_id: work_items(:puzzletime),
                                                          work_date: work_date,
                                                          ticket: '#1',
                                                          description: 'desc',
                                                          hours: '00:45' }
    }
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
    work_items(:allgemein).update(closed: false)
    login_as(:pascal)
    work_date = Time.zone.today + 10
    post :create, params: {
                               ordertime: { account_id: work_items(:allgemein),
                                                          work_date: work_date,
                                                          from_start_time: '8:00',
                                                          to_end_time: '10:15' }
    }
    assert_redirected_to action: 'index', week_date: work_date
    assert flash[:alert].blank?
    assert_match(/Zeit.*erfolgreich erstellt/, flash[:notice])
    assert_equal StartStopType::INSTANCE, Ordertime.last.report_type
    assert_equal '08:00', Ordertime.last.from_start_time.strftime('%H:%M')
    assert_equal '10:15', Ordertime.last.to_end_time.strftime('%H:%M')
    assert_equal 2.25, Ordertime.last.hours
  end

  def test_create_with_missing_start_time
    work_items(:allgemein).update(closed: false)
    work_date = Time.zone.today + 10
    post :create, params: {
                               ordertime: { account_id: work_items(:allgemein),
                                                          work_date: work_date,
                                                          to_end_time: '10:15' }
    }
    assert_match(/Anfangszeit ist ungültig/, @response.body)
  end

  def test_create_with_hours_when_from_to_times_required
    work_items(:allgemein).update(closed: false)
    accounting_posts(:puzzletime).update_column(:from_to_times_required, true)
    work_date = Time.zone.today + 10
    post :create, params: {
                               ordertime: { account_id: work_items(:puzzletime),
                                                          work_date: work_date,
                                                          hours: '00:45' }
    }
    assert_equal ['Von muss angegeben werden', 'Bis muss angegeben werden'], assigns(:worktime).errors.full_messages
    assert_match(/Von muss angegeben werden/, @response.body)
  end

  def test_create_with_from_to_times_when_required
    accounting_posts(:puzzletime).update_column(:from_to_times_required, true)
    work_date = Time.zone.today + 10
    post :create, params: {
                               ordertime: { account_id: work_items(:puzzletime),
                                                          work_date: work_date,
                                                          from_start_time: '00:45',
                                                          to_end_time: '00:46' }
    }
    assert assigns(:worktime).valid?
  end

  def test_create_with_overlapping
    work_date = Time.zone.today + 10
    Fabricate(:ordertime,
              employee: employees(:long_time_john),
              work_date: work_date,
              from_start_time: '9:00',
              to_end_time: '10:00',
              work_item: work_items(:webauftritt))
    work_items(:allgemein).update(closed: false)
    login_as(:long_time_john)
    post :create, params: {
                               ordertime: { account_id: work_items(:allgemein),
                                                          work_date: work_date,
                                                          from_start_time: '8:00',
                                                          to_end_time: '10:15' }
    }
    assert_redirected_to action: 'index', week_date: work_date
    assert flash[:alert].blank?
    assert_match(/Zeit.*erfolgreich erstellt/, flash[:notice])
    assert_match(/Überlappung.*Webauftritt/m, flash[:warning])
  end

  def test_create_with_no_employment
    # half_year_maria 2006-07-01 - 2006-12-31
    work_date = '2017-07-24'

    login_as :half_year_maria

    post :create, params: {
      ordertime: {
        account_id: work_items(:allgemein),
        work_date: work_date,
        hours: 8
      }
    }
    assert_redirected_to action: 'index', week_date: work_date
    assert flash[:alert].blank?
    assert_match(/Zeit.*erfolgreich erstellt/, flash[:notice])
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
      ordertime: {
        account_id: work_items(:allgemein),
        work_date: work_date,
        hours: 8
      }
    }
    assert_redirected_to action: 'index', week_date: work_date
    assert flash[:alert].blank?
    assert_match(/Zeit.*erfolgreich erstellt/, flash[:notice])
    assert_match(/unbezahlter Urlaub/, flash[:warning])
  end

  def test_create_other
    work_items(:allgemein).update(closed: false)
    post :create, params: {
                               ordertime: { account_id: work_items(:allgemein),
                                                          work_date: Time.zone.today,
                                                          hours: '5:30',
                                                          employee_id: employees(:lucien) }
    }
    assert_equal employees(:lucien), Ordertime.last.employee
  end

  def test_create_other_without_permission_changes_employee_id
    work_items(:allgemein).update(closed: false)
    login_as(:lucien)

    assert_difference('Ordertime.count') do
      post :create, params: {
                                 ordertime: { account_id: work_items(:allgemein),
                                                            work_date: Time.zone.today,
                                                            hours: '5:30',
                                                            employee_id: employees(:mark).id }
      }
      assert_equal employees(:lucien).id, Ordertime.last.employee_id
    end
  end

  [:employee, :responsible, :manager].each do |role|
    test "create_as_#{role}_on_closed_order" do
      login_as(roles_users[role])
      work_items(:puzzletime).update(closed: true)

      assert_no_difference('Ordertime.count') do
        post :create, params: {
                                   ordertime: { account_id: work_items(:puzzletime),
                                                              work_date: Time.zone.today,
                                                              ticket: '#1',
                                                              description: 'desc',
                                                              hours: '00:45' }
        }
      end
      assert_includes assigns(:worktime).errors.messages[:base], 'Auf geschlossene Aufträge und/oder Positionen kann nicht gebucht werden.'
    end
  end

  def test_edit_other_as_order_responsible
    ordertime = Fabricate(:ordertime, work_item: work_items(:hitobito_demo_app), employee: employees(:pascal))
    login_as(:lucien)
    assert_nothing_raised do
      get :edit, params: { id: ordertime.id }
    end
  end

  def test_edit_other_without_permission
    login_as(:long_time_john)
    assert_raises(CanCan::AccessDenied) do
      get :edit, params: { id: worktimes(:wt_mw_puzzletime).id }
    end
  end

  def test_update
    worktime = worktimes(:wt_mw_puzzletime)
    put :update, params: { id: worktime, ordertime: { hours: '1:30' } }

    worktime.reload
    assert_redirected_to action: 'index', week_date: worktime.work_date
    assert flash[:alert].blank?
    assert_match(/Zeit.*aktualisiert/, flash[:notice])
    assert_equal HoursDayType::INSTANCE, worktime.report_type
    assert_nil worktime.from_start_time
    assert_nil worktime.to_end_time
    assert_equal 1.5, worktime.hours
  end

  def test_update_other_as_order_responsible
    ordertime = Fabricate(:ordertime, work_item: work_items(:hitobito_demo_app), employee: employees(:pascal))
    login_as(:lucien)
    assert_nothing_raised do
      put :update, params: { id: ordertime, ordertime: { hours: '1:30' } }
    end
    assert_redirected_to action: 'split'
  end

  def test_update_other_without_permission
    worktime = worktimes(:wt_mw_puzzletime)
    login_as(:long_time_john)
    assert_raises(CanCan::AccessDenied) do
      put :update, params: { id: worktime, ordertime: { hours: '1:30' } }
    end
  end

  [:employee, :responsible, :manager].each do |role|
    test "update_as_#{role}_on_closed_order" do
      user = roles_users[role]
      login_as(user)
      ordertime = Fabricate(:ordertime, work_item: work_items(:puzzletime), employee: employees(user))
      work_items(:puzzletime).update(closed: true)
      assert_raises(CanCan::AccessDenied) do
        post :update, params: { id: ordertime.id, hours: 4 }
      end
    end
  end

  def test_split
    worktime = worktimes(:wt_pz_allgemein)
    session[:split] = WorktimeEdit.new(worktime)
    get :split
    assert_template 'split'
  end

  def test_incomplete_split
    worktime = worktimes(:wt_pz_allgemein)
    put :update, params: { id: worktime, ordertime: { hours: '0:30', employee_id: employees(:pascal) } }
    assert_redirected_to action: 'split'
    assert_not_nil assigns(:split)
  end

  def test_complete_split
    worktime = worktimes(:wt_pz_allgemein)
    put :update, params: { id: worktime, ordertime: { hours: '1:00', employee_id: employees(:pascal) } }
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
        params: {
          id: worktime,
          ordertime: { hours: '0:30',
                       employee_id: employees(:pascal),
                       work_date: worktime.work_date,
                       account_id: worktime.work_item_id }
        }
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
        params: {
          id: worktime,
          ordertime: { hours: '0:24',
                       employee_id: employees(:pascal),
                       work_date: worktime.work_date,
                       account_id: worktime.work_item_id }
        }
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
        params: {
          id: worktime,
          ordertime: { hours: '0:24',
                       employee_id: employees(:mark),
                       work_date: nil,
                       account_id: worktime.work_item_id }
        }
    assert_template 'split'
    assert_match(/muss ausgefüllt werden/, assigns(:worktime).errors[:work_date].first)
  end

  def test_destroy
    worktime = worktimes(:wt_mw_puzzletime)
    work_date = worktime.work_date
    delete :destroy, params: { id: worktime }
    assert_redirected_to action: 'index', week_date: work_date
    assert_nil Ordertime.find_by_id(worktime.id)
  end

  def test_destroy_without_permission
    worktime = worktimes(:wt_pz_puzzletime)
    assert_no_difference('Worktime.count') do
      assert_raises(CanCan::AccessDenied) do
        delete :destroy, params: { id: worktime.id }
      end
    end
  end

  [:employee, :responsible, :manager].each do |role|
    test "destroy_as_#{role}_on_closed_order" do
      user = roles_users[role]
      login_as(user)
      ordertime = Fabricate(:ordertime, work_item: work_items(:puzzletime), employee: employees(user))
      work_items(:puzzletime).update(closed: true)
      assert_no_difference('Ordertime.count') do
        assert_raises(CanCan::AccessDenied) do
          delete :destroy, params: { id: ordertime.id }
        end
      end
    end
  end

  test 'committed worktimes may not be created by user' do
    e = employees(:pascal)
    e.update!(committed_worktimes_at: '2015-08-31')
    login_as(:pascal)
    post :create, params: {
                               ordertime: { account_id: work_items(:webauftritt).id,
                                                          work_date: '2015-08-31',
                                                          hours: '2',
                                                          employee_id: e.id }
    }
    assert_template('new')
    assert assigns(:worktime).errors[:work_date].present?
  end

  test 'uncommitted worktimes may be created by user' do
    e = employees(:pascal)
    e.update!(committed_worktimes_at: '2015-08-31')
    login_as(:pascal)
    post :create, params: {
                               ordertime: { account_id: work_items(:webauftritt).id,
                                                          work_date: '2015-09-01',
                                                          hours: '2',
                                                          employee_id: e.id }
    }
    assert flash[:notice].present?
  end

  test 'committed worktimes may be created by manager' do
    e = employees(:pascal)
    e.update!(committed_worktimes_at: '2015-08-31')
    login_as(:mark)
    post :create, params: {
                               ordertime: { account_id: work_items(:webauftritt).id,
                                                          work_date: '2015-08-31',
                                                          hours: '2',
                                                          employee_id: e.id }
    }
    assert flash[:notice].present?
  end

  test 'committed worktimes may not be updated by user' do
    e = employees(:pascal)
    t = Ordertime.create!(employee: e,
                          work_date: '2015-08-31',
                          hours: 2,
                          work_item: work_items(:webauftritt),
                          report_type: 'absolute_day')
    e.update!(committed_worktimes_at: '2015-09-30')
    login_as(:pascal)
    assert_raises(CanCan::AccessDenied) do
      put :update, params: { id: t.id, ordertime: { hours: '3' } }
    end
  end

  test 'committed worktimes may be updated by manager' do
    e = employees(:pascal)
    t = Ordertime.create!(employee: e,
                          work_date: '2015-08-31',
                          hours: 2,
                          work_item: work_items(:webauftritt),
                          report_type: 'absolute_day')
    e.update!(committed_worktimes_at: '2015-09-30')
    login_as(:mark)
    put :update, params: { id: t.id, ordertime: { description: 'bla bla' } }
    assert flash[:notice].present?
    assert_equal 'bla bla', t.reload.description
  end

  test 'committed worktimes may not change work date forwards by user' do
    e = employees(:pascal)
    t = Ordertime.create!(employee: e,
                          work_date: '2015-08-31',
                          hours: 2,
                          work_item: work_items(:webauftritt),
                          report_type: 'absolute_day')
    e.update!(committed_worktimes_at: '2015-09-30')
    login_as(:pascal)
    assert_raises(CanCan::AccessDenied) do
      put :update, params: { id: t.id, ordertime: { work_date: '2015-10-10' } }
    end
  end

  test 'committed worktimes may not change work date backwards by user' do
    e = employees(:pascal)
    t = Ordertime.create!(employee: e,
                          work_date: '2015-10-10',
                          hours: 2,
                          work_item: work_items(:webauftritt),
                          report_type: 'absolute_day')
    e.update!(committed_worktimes_at: '2015-09-30')
    login_as(:pascal)

    put :update, params: { id: t.id, ordertime: { work_date: '2015-08-31' } }
    assert_template('edit')
    assert assigns(:worktime).errors[:work_date].present?
  end

  test 'committed worktimes may not be destroyed by user' do
    e = employees(:pascal)
    t = Ordertime.create!(employee: e,
                          work_date: '2015-08-31',
                          hours: 2,
                          work_item: work_items(:webauftritt),
                          report_type: 'absolute_day')
    e.update!(committed_worktimes_at: '2015-09-30')
    login_as(:pascal)

    assert_raises(CanCan::AccessDenied) { delete :destroy, params: { id: t.id } }
  end

end
