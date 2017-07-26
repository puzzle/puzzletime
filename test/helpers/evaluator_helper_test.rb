# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


require 'test_helper'

class EvaluatorHelperTest < ActionView::TestCase
  include UtilityHelper
  include FormatHelper
  include EvaluatorHelper

  test '#employee_infos with period' do
    setup_employment
    period = Period.with(Date.new(2010, 1, 1), Date.new(2010, 1, 31))
    infos = employee_infos(employees(:various_pedro), period)
    assert_equal [['<a href="http://test.host/employees/2/employments">Beschäftigungsgrad</a>', '100 %'],
                  ['Software Engineer Senior', '80 %'],
                  ['Member of the Technical Board', '20 %']], infos.first
    assert_equal ['Überstundensaldo', 'per Gestern'], infos.second.map(&:first)
    assert_equal ['Feriensaldo per 31.12.2010', 'Guthaben 2010', 'Übertrag 2009'], infos.third.map(&:first)
  end

  test '#employee_infos without period' do
    setup_employment
    infos = employee_infos(employees(:various_pedro))
    assert_equal [['<a href="http://test.host/employees/2/employments">Beschäftigungsgrad</a>', '100 %'],
                  ['Software Engineer Senior', '80 %'],
                  ['Member of the Technical Board', '20 %']], infos.first
    assert_equal ['Überstundensaldo', 'per Gestern'], infos.second.map(&:first)
    assert_equal ["Feriensaldo per 31.12.#{Time.zone.today.year}",
                  "Guthaben #{Time.zone.today.year}",
                  "Übertrag #{Time.zone.today.year - 1}"], infos.third.map(&:first)
  end

  private

  def setup_employment
    pedro = employees(:various_pedro)
    pedro.update!(department: departments(:devone)) # 100%
    pedro.employments.last.employment_roles_employments.create!(
      employment_role_id: employment_roles(:software_engineer).id,
      employment_role_level_id: employment_role_levels(:senior).id,
      percent: 80
    )
    pedro.employments.last.employment_roles_employments.create!(
      employment_role_id: employment_roles(:technical_board).id,
      percent: 20
    )
  end

end
