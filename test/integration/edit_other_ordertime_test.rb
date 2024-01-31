#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class EditOtherOrdertimeTest < ActionDispatch::IntegrationTest
  fixtures :all
  setup :login

  test 'create ordertime' do
    create_ordertime
  end

  test 'update ordertime with same hours' do
    ordertime = create_ordertime
    put ordertime_path(ordertime), params: { ordertime: { hours: '8:30' } }
    follow_redirect!

    assert_response :success
    assert_equal '/evaluator/details', path
    assert_equal 'Alle Arbeitszeiten wurden erfasst', flash[:notice]
    assert_in_delta(8.5, ordertime.hours)
  end

  test 'update ordertime with more hours' do
    ordertime = create_ordertime
    put ordertime_path(ordertime), params: { ordertime: { hours: '9:30' } }

    assert_response :success
    assert_equal ordertime_path(ordertime), path
    assert_match(/Die gesamte Anzahl Stunden kann nicht vergrössert werden/, response.body)
    ordertime.reload

    assert_in_delta(8.5, ordertime.hours)
  end

  test 'update ordertime with less hours' do
    ordertime = create_ordertime
    put ordertime_path(ordertime), params: { ordertime: { hours: '7:30' } }
    follow_redirect!

    assert_response :success
    assert_equal split_ordertimes_path, path
    assert_match(/Die Zeiten wurden noch nicht gespeichert/, response.body)
    assert_match(/Bitte schliessen sie dazu den Aufteilungsprozess ab/, response.body)
    ordertime.reload

    assert_equal ordertime, Ordertime.last # splitted times will be persisted later as new records
    assert_in_delta(8.5, ordertime.hours)

    post create_part_ordertimes_path,
         params: {
           ordertime: {
             employee_id: employees(:mark).id,
             account_id: work_items(:allgemein).id,
             work_date: Time.zone.today,
             hours: '1:00'
           }
         }
    follow_redirect!

    assert_response :success
    assert_equal '/evaluator/details', path
    assert_match(/Alle Arbeitszeiten wurden erfasst/, response.body)
    assert_in_delta(7.5, Ordertime.order(id: :desc).limit(2).second.hours)
    assert_in_delta(1.0, Ordertime.order(id: :desc).limit(2).first.hours)
  end

  private

  def create_ordertime
    employee = employees(:lucien)
    post '/ordertimes',
         params: {
           ordertime: {
             employee_id: employee.id,
             account_id: work_items(:allgemein).id,
             work_date: Time.zone.today,
             hours: '8:30'
           }
         }
    follow_redirect!

    assert_response :success
    assert_equal '/evaluator/details', path
    ordertime = Ordertime.last

    assert_in_delta(8.5, ordertime.hours)
    ordertime
  end

  def login
    login_as(:mark)
  end
end
