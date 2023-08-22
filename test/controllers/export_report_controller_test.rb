#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class ExportReportControllerTest < ActionController::TestCase
  setup :login

  test 'GET export denies access for non-managment employee' do
    employees(:mark).update!(management: false)
    assert_raises CanCan::AccessDenied do
      get :index
    end
  end

  test 'GET export renders page to select date' do
    get :index

    assert_template 'index'
    assert_match(/Stichdatum/, response.body)
  end

  test 'GET export has a button to download role_distribution csv' do
    get :index

    assert_match(/Funktionsanteile/, response.body)
  end

  test 'GET export role_distribution with format csv renders csv' do
    get :index, params: {
      date: I18n.l(Date.new(2000, 1, 23)),
      report: :role_distribution,
      format: :csv
    }

    assert_csv_http_headers('puzzletime_funktionsanteile_20000123.csv')
    assert_match(/Funktionsanteile per 23.01.2000/, response.body)
  end

  test 'GET export has a button to download overtime_vacations csv' do
    get :index

    assert_match('Überzeit/Ferien', response.body)
  end

  test 'GET export overtime_vacations with format csv renders csv' do
    get :index, params: {
      date: I18n.l(Date.new(2000, 1, 23)),
      report: :overtime_vacations,
      format: :csv
    }

    assert_csv_http_headers('puzzletime_überzeit_ferien_20000123.csv')
    assert_match('Überzeit/Ferien per 23.01.2000', response.body)
  end

  private

  def assert_csv_http_headers(filename)
    assert_includes response.headers, 'Content-Type', 'Content-Disposition'
    assert_equal 'text/csv; charset=utf-8', response.headers['Content-Type']

    filename_slug = I18n.transliterate(filename)
    filename_utf8 = CGI.escape(filename)

    assert_equal "attachment; filename=\"#{filename_slug}\"; filename*=UTF-8''#{filename_utf8}", response.headers['Content-Disposition']
  end
end
