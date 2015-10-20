require 'test_helper'

class EvaluatorControllerTest < ActionController::TestCase
  setup :login

  def expected_csv_header
    'Datum,Stunden,Von Zeit,Bis Zeit,Reporttyp,Verrechenbar,Mitarbeiter,Position,Ticket,Bemerkungen'
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
    assert_equal response.headers['Content-Type'], 'text/csv'
    assert_equal response.headers['Content-Disposition'], "attachment; filename=\"#{filename}\""
  end

  %w(userworkitems userabsences).each do |evaluation|
    test "GET index #{evaluation}" do
      get :index, evaluation: evaluation
      assert_template 'user_overview'
    end

    test "GET export csv #{evaluation}" do
      get :export_csv, evaluation: evaluation
      assert_csv_http_headers('puzzletime-waber_mark.csv')
      assert_match expected_csv_header, csv_header
    end
  end

  test 'GET export_csv userworkitems csv format' do
    get :export_csv, evaluation: 'userworkitems'
    assert_match expected_csv_header, csv_header
    assert_equal 3, csv_data_lines.size
    assert_match '06.12.2006,5.0,"","",absolute_day,true,Waber Mark,PITC-AL: Allgemein,,', csv_data_lines.first
  end

  %w(clients employees departments).each do |evaluation|
    test "GET index #{evaluation}" do
      get :index, evaluation: evaluation
      assert_template 'overview'
    end

    test "GET details #{evaluation}" do
      get :details, evaluation: evaluation, category_id: division_id(evaluation)
      assert_template 'details'
    end

    test "GET export csv #{evaluation}" do
      get :export_csv, evaluation: evaluation
      assert_csv_http_headers('puzzletime.csv')
      assert_match expected_csv_header, csv_header
      assert_equal 9, csv_data_lines.size
      assert_match '29.11.2006,1.0,"","",absolute_day,true,Zumkehr Pascal,PITC-AL: Allgemein,,', csv_data_lines.first
    end
  end

  test 'GET report contains all hours' do
    get :report, evaluation: 'workitememployees',
                 category_id: work_items(:allgemein),
                 division_id: employees(:pascal)

    assert_template 'report'
    total = assigns(:times).sum(:hours)
    assert_match /Total Stunden.*#{total}/m, response.body
  end

  test 'GET report contains all hours with combined tickets' do
    Fabricate(:ordertime,
              employee: employees(:pascal),
              work_item: work_items(:allgemein),
              ticket: 123)
    Fabricate(:ordertime,
              employee: employees(:pascal),
              work_item: work_items(:allgemein),
              hours: 5)

    get :report, evaluation: 'workitememployees',
                 category_id: work_items(:allgemein),
                 division_id: employees(:pascal),
                 combine_on: true,
                 combine: 'ticket'

    assert_template 'report'
    total = assigns(:times).sum(:hours)
    assert_equal 8, total
    assert_match /Total Stunden.*#{total}/m, response.body
  end

  test 'GET report with param show_ticket=1 shows tickets' do
    ticket_label = 'ticket-123'
    Fabricate(:ordertime,
              employee: employees(:pascal),
              work_item: work_items(:allgemein),
              ticket: ticket_label)
    get :report, evaluation: 'workitememployees',
                 category_id: work_items(:allgemein),
                 division_id: employees(:pascal),
                 show_ticket: '1'

    assert_template 'report'
    assert_match %r{<th>Ticket</th>}, response.body
    assert_match %r{<td[^>]*>#{ticket_label}</td>}, response.body
  end

  def division_id(evaluation)
    evaluation.singularize.classify.constantize.first.id
  end
end
