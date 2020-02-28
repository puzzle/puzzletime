#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


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
    get :index, params: { sort: 'department', sort_dir: 'asc' }
    assert_equal %w(John Pablo Pedro), assigns(:employees).map(&:firstname)
  end

  test 'GET index with sorting by last employment' do
    employments(:next_year).tap do |e|
      e.end_date = Date.new(2007, 12, 31)
      e.save!
    end
    Fabricate(:employment, {
      employee: employees(:next_year_pablo),
      percent: 100,
      start_date: Date.new(2017, 7, 24),
      end_date: nil
    })
    get :index, params: { sort: 'latest_employment', sort_dir: 'desc' }
    assert_equal %w(John Pedro Pablo), assigns(:employees).map(&:firstname)
    expected = [Date.new(1990, 1, 1), Date.new(2005, 11, 1), Date.new(2017, 7, 24)]
    actual = assigns(:employees).map do |e|
      assigns(:employee_employment)[e]
    end
    assert_equal expected, actual
  end

  test 'GET index with searching' do
    get :index, params: { q: 'ped' }
    assert_equal %w(Pedro), assigns(:employees).map(&:firstname)
  end

  test 'GET show' do
    get :show, params: { id: employees(:various_pedro).id }
    assert_equal employees(:various_pedro), assigns(:employee)
  end

  test 'GET show vcard' do
    get :show, params: { id: employees(:various_pedro).id }, format: :vcf
    assert_equal employees(:various_pedro), assigns(:employee)
    assert_match(/^BEGIN:VCARD/, response.body)
    assert_match(/Pedro/, response.body)
  end

  test 'GET show hide classified data to non management' do
    login_as(:next_year_pablo)
    get :show, params: { id: employees(:various_pedro).id }
    refute_match(/AHV-Nummer/, response.body)
  end

  test 'GET show show classified data to responsible' do
    login_as(:lucien)
    get :show, params: { id: employees(:various_pedro).id }
    assert_match(/AHV-Nummer/, response.body)
  end

  test 'GET show show classified data to management' do
    login_as(:half_year_maria)
    get :show, params: { id: employees(:various_pedro).id }
    assert_match(/AHV-Nummer/, response.body)
  end

  test 'GET show show classified data to owner' do
    login_as(:various_pedro)
    get :show, params: { id: employees(:various_pedro).id }
    assert_match(/AHV-Nummer/, response.body)
  end

end
