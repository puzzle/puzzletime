# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class OrderReportsControllerTest < ActionController::TestCase
  setup :login

  test 'GET index without filter has some default params set' do
    get :index

    assert_predicate assigns(:report), :filters_defined?

    get :index, params: { status_preselection: 'closed' }

    assert_predicate assigns(:report), :filters_defined?

    get :index, params: { status_preselection: 'not_closed' }

    assert_predicate assigns(:report), :filters_defined?
  end

  test 'GET index with department filter contains correct entries' do
    get :index, params: { department_id: departments(:devone).id }

    assert_predicate assigns(:report), :filters_defined?
    assert_equal orders(:puzzletime, :webauftritt), assigns(:report).entries.map(&:order)
  end

  test 'GET index with multiple kind filter contains correct entries' do
    orders(:webauftritt).update!(kind: order_kinds(:schulung))
    orders(:puzzletime).update!(kind: order_kinds(:mandat))
    get :index, params: { kind_id: order_kinds(:mandat, :projekt).map(&:id) }

    assert_predicate assigns(:report), :filters_defined?
    assert_equal orders(:allgemein, :puzzletime), assigns(:report).entries.map(&:order)
  end

  test 'GET index with period filter contains correct entries' do
    get :index, params: { start_date: '6.12.2006', end_date: '7.12.2006' }

    assert_predicate assigns(:report), :filters_defined?
    assert_equal orders(:allgemein, :puzzletime), assigns(:report).entries.map(&:order)
  end

  test 'GET index with invalid period filter shows error' do
    get :index, params: { start_date: '31.12.2006', end_date: '1.12.2006' }

    assert_predicate flash[:alert], :present?
  end

  test 'GET index csv exports csv file' do
    get :index, params: { responsible_id: employees(:lucien).id }, format: :csv

    assert_match(/Kunde,Kategorie,Auftrag/, response.body)
  end
end
