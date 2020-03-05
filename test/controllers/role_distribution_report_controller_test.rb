#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class RoleDistributionReportControllerTest < ActionController::TestCase
  setup :login

  test 'GET export_role_distribution denies access for non-managment employee' do
    employees(:mark).update!(management: false)
    assert_raises CanCan::AccessDenied do
      get :index
    end
  end

  test 'GET export_role_distribution renders page to select date' do
    get :index
    assert_template 'index'
    assert_match(/Stichdatum/, response.body)
    assert_match(/CSV herunterladen/, response.body)
  end

  test 'GET export_role_distribution with format csv renders csv' do
    get :index, params: { date: I18n.l(Date.new(2000, 1, 23)), format: :csv }
    assert_csv_http_headers('puzzletime_funktionsanteile_20000123.csv')
    assert_match(/Funktionsanteile per 23.01.2000/, response.body)
  end

  private

  def assert_csv_http_headers(filename)
    assert_includes response.headers, 'Content-Type', 'Content-Disposition'
    assert_equal 'text/csv; charset=utf-8; header=present', response.headers['Content-Type']
    assert_equal "attachment; filename=\"#{filename}\"", response.headers['Content-Disposition']
  end
end
