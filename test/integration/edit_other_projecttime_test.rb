# encoding: UTF-8

require 'test_helper'

class EditOtherProjecttimeTest < ActionDispatch::IntegrationTest

  fixtures :all
  setup :login

  test 'create projecttime' do
    create_projecttime
  end

  test 'update projecttime with same hours' do
    projecttime = create_projecttime
    put_via_redirect projecttime_path(projecttime), projecttime: { hours: '8:30' }
    assert_response :success
    assert_equal '/evaluator/details', path
    assert_equal 'Alle Arbeitszeiten wurden erfasst', flash[:notice]
    assert_equal 8.5, projecttime.hours
  end

  test 'update projecttime with more hours' do
    projecttime = create_projecttime
    put_via_redirect projecttime_path(projecttime), projecttime: { hours: '9:30' }
    assert_response :success
    assert_equal projecttime_path(projecttime), path
    assert_match(/Die gesamte Anzahl Stunden kann nicht vergrössert werden/, response.body)
    projecttime.reload
    assert_equal 8.5, projecttime.hours
  end

  test 'update projecttime with less hours' do
    projecttime = create_projecttime
    put_via_redirect projecttime_path(projecttime), projecttime: { hours: '7:30' }
    assert_response :success
    assert_equal split_projecttimes_path, path
    assert_match(/Die Zeiten wurden noch nicht gespeichert/, response.body)
    assert_match(/Bitte schliessen sie dazu den Aufteilungsprozess ab/, response.body)
    projecttime.reload
    assert_equal projecttime, Projecttime.last # splitted times will be persisted later as new records
    assert_equal 8.5, projecttime.hours

    post_via_redirect create_part_projecttimes_path,
      projecttime: { employee_id: employees(:mark).id,
                     account_id: projects(:allgemein).id,
                     work_date: Date.today,
                     hours: '1:00'  }
    assert_response :success
    assert_equal '/evaluator/details', path
    assert_match(/Alle Arbeitszeiten wurden erfasst/, response.body)
    assert_equal 7.5, Projecttime.order(id: :desc).limit(2).second.hours
    assert_equal 1.0, Projecttime.order(id: :desc).limit(2).first.hours
  end

  private

  def create_projecttime
    employee = employees(:mark)
    post_via_redirect '/projecttimes',
      projecttime: { employee_id: employee.id,
                     account_id: projects(:allgemein).id,
                     work_date: Date.today,
                     hours: '8:30'  }
    assert_response :success
    assert_equal '/evaluator/details', path
    projecttime = Projecttime.last
    assert_equal 8.5, projecttime.hours
    projecttime
  end

  def login
    post_via_redirect '/login/login', user: 'GGG', pwd: 'Yaataw'
    assert_response :success
    assert_equal '/', path
    assert assigns(:week_days)
  end
end
