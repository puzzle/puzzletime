# encoding: UTF-8

require 'test_helper'

class WorktimesControllerTest < ActionController::TestCase
  setup :login

  def test_index
    get :index
    assert_equal 7, assigns(:week_days).count
    assert_equal Time.zone.today.at_beginning_of_week, assigns(:week_days).first
    assert_equal Time.zone.today.at_end_of_week, assigns(:week_days).last
  end

  def test_week_switcher
    get :index, params: { week_date: '2013-12-31' }
    assert_equal 7, assigns(:week_days).count
    assert_equal Date.new(2013, 12, 30), assigns(:week_days).first
    assert_equal Date.new(2014, 1, 5), assigns(:week_days).last
  end

  def test_date_picker_week_switcher
    get :index, params: { week_date: '31.12.2013' } # datepicker uses german locale
    assert_equal 7, assigns(:week_days).count
    assert_equal Date.new(2013, 12, 30), assigns(:week_days).first
    assert_equal Date.new(2014, 1, 5), assigns(:week_days).last
  end

  def test_worktimes
    get :index, params: { week_date: '2006-12-8' }
    assert_equal 4, assigns(:worktimes).count
    assert_equal Date.new(2006, 12, 6), assigns(:worktimes).first.work_date
    assert_equal Date.new(2006, 12, 9), assigns(:worktimes).last.work_date
  end

  test 'no modify buttons for member\s committed time period' do
    create_time_entries(:pascal)
    login_as(:pascal)

    commit_times(:pascal)

    get :index, params: { week_date: months_first_day.to_s }
    assert_no_modify_buttons
  end

  test 'modify buttons for member\s not committed time period' do
    create_time_entries(:pascal)
    login_as(:pascal)

    get :index, params: { week_date: months_first_day.to_s }
    assert_modify_buttons
  end

  test 'no modify buttons for manager\s committed time period' do
    create_time_entries(:mark)
    login_as(:mark)

    commit_times(:mark)

    get :index, params: { week_date: months_first_day.to_s }
    assert_no_modify_buttons
  end

  test 'destroy button/edit link for invoice with status \'draft\'' do
    create_time_entries(:pascal)
    @ordertime.update(invoice: create_invoice('draft'))
    login_as(:pascal)

    get :index, params: { week_date: months_first_day.to_s }
    assert_modify_buttons
    assert_select('.entry:not(.is-empty) a.entry-link', count: 2)
  end

  test 'no destroy button/edit link for invoice with status \'sent\'' do
    create_time_entries(:pascal)
    @ordertime.update(invoice: create_invoice('sent'))
    login_as(:pascal)

    get :index, params: { week_date: months_first_day.to_s }
    assert_select('a i.icon-duplicate', count: 2)
    assert_select('a i.icon-delete', count: 1)
    assert_select('a i.icon-add', count: 7 * 2)
    assert_select('.entry:not(.is-empty) a.entry-link', count: 1)
  end

  test 'no destroy button/edit link for invoice with status \'paid\'' do
    create_time_entries(:pascal)
    @ordertime.update(invoice: create_invoice('paid'))
    login_as(:pascal)

    get :index, params: { week_date: months_first_day.to_s }
    assert_select('a i.icon-duplicate', count: 2)
    assert_select('a i.icon-delete', count: 1)
    assert_select('a i.icon-add', count: 7 * 2)
    assert_select('.entry:not(.is-empty) a.entry-link', count: 1)
  end

  test 'no destroy button/edit link for invoice with status \'partially_paid\'' do
    create_time_entries(:pascal)
    @ordertime.update(invoice: create_invoice('partially_paid'))
    login_as(:pascal)

    get :index, params: { week_date: months_first_day.to_s }
    assert_select('a i.icon-duplicate', count: 2)
    assert_select('a i.icon-delete', count: 1)
    assert_select('a i.icon-add', count: 7 * 2)
    assert_select('.entry:not(.is-empty) a.entry-link', count: 1)
  end

  private

  def assert_modify_buttons
    assert_select('a i.icon-duplicate', count: 2)
    assert_select('a i.icon-delete', count: 2)
    assert_select('a i.icon-add', count: 7 * 2)
  end

  def assert_no_modify_buttons
    assert_select('a i.icon-duplicate', count: 2)
    assert_select('a i.icon-delete', count: 0)
    assert_select('a i.icon-add', count: 0)
  end

  def create_time_entries(name)
    @ordertime = Fabricate(:ordertime, employee: employees(name),
                                       work_item: work_items(:puzzletime),
                                       work_date: months_first_day)
    @absencetime = Fabricate(:absencetime, employee: employees(name),
                                           work_date: months_first_day)
  end

  def create_invoice(status)
    Fabricate(:invoice, order: orders(:puzzletime), status: status, due_date: Date.new(2000, 1, 23))
  end

  def commit_times(name)
    employees(name).update!(committed_worktimes_at:
                            Date.today.at_end_of_month)
  end

  def months_first_day
    Date.today.at_beginning_of_month
  end


end
