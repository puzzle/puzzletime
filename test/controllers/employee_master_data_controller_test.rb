# encoding: UTF-8

require 'test_helper'

class EmployeeMasterDataControllerTest < ActionController::TestCase

  setup :login

  test 'GET index' do
    get :index
    assert_equal %w(Pedro John Pablo), assigns(:employees).map(&:firstname)
  end

  test 'GET index excludes employees not employed today' do
    employees(:various_pedro).employments.last.update!(end_date: Time.zone.today - 1.day)
    get :index
    assert_equal %w(John Pablo), assigns(:employees).map(&:firstname)
  end

  test 'GET index with sorting' do
    employees(:long_time_john).update!(department_id: departments(:devone).id)
    employees(:next_year_pablo).update!(department_id: departments(:devtwo).id)
    employees(:various_pedro).update!(department_id: departments(:sys).id)
    get :index, sort: 'department', sort_dir: 'asc'
    assert_equal %w(John Pablo Pedro), assigns(:employees).map(&:firstname)
  end

  test 'GET index with searching' do
    get :index, q: 'ped'
    assert_equal %w(Pedro), assigns(:employees).map(&:firstname)
  end

  test 'GET show' do
    get :show, id: employees(:various_pedro).id
    assert_equal employees(:various_pedro), assigns(:employee)
  end

  test 'GET show vcard' do
    get :show, id: employees(:various_pedro).id, format: :vcf
    assert_equal employees(:various_pedro), assigns(:employee)
    assert_match(/^BEGIN:VCARD/, response.body)
    assert_match(/Pedro/, response.body)
  end

end
