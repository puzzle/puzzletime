# encoding: utf-8

require 'test_helper'

class WorkloadReportTest < ActionDispatch::IntegrationTest

  setup :login

  test 'member detail links are set-up on first page load' do
    find('a[data-toggle="employee-8-ordertimes"]').click
    assert_selector 'tbody#employee-8-ordertimes'
  end

  test 'member detail links are set-up after changing filter' do
    find('input#start_date').click
    all('td[data-handler=selectDay]').last.click

    find('a[data-toggle="employee-6-ordertimes"]').click
    assert_selector 'tbody#employee-6-ordertimes'
  end

  private

  def login
    login_as(:mark,
             reports_workload_path(start_date: '1.1.2006',
                                   end_date: '31.12.2006',
                                   department_id: departments(:devtwo).id))
  end

end
