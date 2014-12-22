require 'test_helper'

class EvaluatorControllerTest < ActionController::TestCase

  setup :login

  %w(userworkitems userabsences).each do |evaluation|

    test "GET index #{evaluation}" do
      get :index, evaluation: evaluation
      assert_template 'user_overview'
    end

    test "GET export csv #{evaluation}" do
      get :export_csv, evaluation: evaluation
      assert_match /Datum,Stunden/, response.body
    end

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
      assert_match /Datum,Stunden/, response.body
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

  def division_id(evaluation)
    evaluation.singularize.classify.constantize.first.id
  end

end
