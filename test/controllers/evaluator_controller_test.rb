# frozen_string_literal: true

#  Copyright (c) 2006-2024, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class EvaluatorControllerTest < ActionController::TestCase
  setup :login

  %w[userworkitems userabsences].each do |evaluation|
    test "GET index #{evaluation}" do
      get :index, params: { evaluation: }

      assert_template evaluation == 'userworkitems' ? 'overview_employee' : 'overview'
      assert_equal %w[-2m -1m 0m -1y 0y 0].map { |p| Period.parse(p) }, assigns(:periods)
    end

    test "GET export csv #{evaluation}" do
      get :export_csv, params: { evaluation: }

      assert_csv_http_headers('puzzletime-waber_mark.csv')
      assert_match expected_csv_header, csv_header
    end
  end

  test 'GET index absences filtered by department' do
    employees(:various_pedro).update(department: departments(:devone))
    get :index, params: { evaluation: 'absences', department_id: departments(:devone).id }

    assert_template 'overview'

    assert_equal assigns(:evaluation).divisions.map(&:department_id).uniq, [departments(:devone).id]
  end

  test 'GET export_csv userworkitems csv format' do
    get :export_csv, params: { evaluation: 'userworkitems' }

    assert_match expected_csv_header, csv_header
    assert_equal 3, csv_data_lines.size
    assert_match '06.12.2006,5.0,"","",0.00,0.00,absolute_day,true,Waber Mark,PITC-AL: Allgemein,,', csv_data_lines.first
  end

  test 'GET index employees' do
    get :index, params: { evaluation: 'employees' }

    assert_template 'employees'
  end

  %w[clients departments].each do |evaluation|
    test "GET index #{evaluation}" do
      get :index, params: { evaluation: }

      assert_template 'overview'
      assert_nil assigns(:order)
    end
  end

  test 'GET index workitememployees' do
    get :index, params: { evaluation: 'workitememployees', category_id: work_items(:allgemein) }

    assert_template 'overview'
    assert_equal work_items(:allgemein).order, assigns(:order)
    assert_select 'a', /#{work_items(:allgemein).order.label_with_workitem_path}/
  end

  %w[clients employees departments].each do |evaluation|
    test "GET details #{evaluation}" do
      get :details, params: { evaluation:, category_id: division_id(evaluation) }

      assert_template 'details'
    end

    test "GET export csv #{evaluation}" do
      get :export_csv, params: { evaluation: }

      assert_csv_http_headers('puzzletime.csv')
      assert_match expected_csv_header, csv_header
      assert_equal 9, csv_data_lines.size
      assert_match '29.11.2006,1.0,"","",0.00,0.00,absolute_day,true,Zumkehr Pascal,PITC-AL: Allgemein,,', csv_data_lines.first
    end
  end

  private

  def expected_csv_header
    'Datum,Stunden,Von Zeit,Bis Zeit,CHF,Stundenansatz CHF,Reporttyp,Verrechenbar,Member,Position,Ticket,Bemerkungen'
  end

  def csv_header
    response.body.lines.first
  end

  def csv_data_lines
    _, *lines = response.body.lines.to_a
    lines
  end

  def assert_csv_http_headers(filename)
    assert_includes response.headers, 'Content-Type', 'Content-Disposition'
    assert_equal 'text/csv; charset=utf-8', response.headers['Content-Type']
    assert_equal "attachment; filename=\"#{filename}\"; filename*=UTF-8''#{filename}",
                 response.headers['Content-Disposition']
  end

  def division_id(evaluation)
    evaluation.singularize.classify.constantize.first.id
  end
end
