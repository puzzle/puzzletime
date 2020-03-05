# -*- coding: utf-8 -*-
#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# coding: utf-8

require 'test_helper'

class RoleDistributionReportTest < ActiveSupport::TestCase
  test '#filename' do
    assert_equal 'puzzletime_funktionsanteile_20100123.csv', report.filename
  end

  test '#to_csv' do
    setup_employments

    title, header, *lines = CSV.parse(report.to_csv)
    assert_equal 'Funktionsanteile per 23.01.2010, GJ 2009/2010', title.first
    assert_equal ['Member', 'Anstellung', 'Wertschöpfung', 'Technical Board', 'Unterstützend'], header

    lines = lines.select { |l| l.any?(&:present?) } # remove empty lines

    assert_equal [['Organisationseinheit devone', '', '', '', ''],
                  ['Dolores Pedro', '100.0%', '65.0%', '15.0%', '20.0%'],
                  ['Sanchez Pablo', '100.0%', '90.0%', '10.0%', '0.0%'],
                  ['Total devone', '200.0%', '155.0%', '25.0%', '20.0%'],
                  ['Organisationseinheit devtwo', '', '', '', ''],
                  ['Neverends John', '90.0%', '90.0%', '0.0%', '0.0%'],
                  ['Total devtwo', '90.0%', '90.0%', '0.0%', '0.0%'],
                  ['', 'Anstellung', 'Wertschöpfung', 'Technical Board', 'Unterstützend'],
                  ['Total FTE', '2.9', '2.45', '0.25', '0.2']], lines
  end

  private

  def report(date = Date.new(2010, 1, 23))
    @report ||= RoleDistributionReport.new(date)
  end

  def setup_employments
    pedro = employees(:various_pedro)
    pedro.update!(department: departments(:devone)) # 100%
    pedro.employments.last.employment_roles_employments.delete_all
    pedro.employments.last.employment_roles_employments.create!(
      employment_role_id: employment_roles(:software_engineer).id,
      employment_role_level_id: employment_role_levels(:senior).id,
      percent: 65
    )
    pedro.employments.last.employment_roles_employments.create!(
      employment_role_id: employment_roles(:management_assistant).id,
      employment_role_level_id: employment_role_levels(:professional).id,
      percent: 20
    )
    pedro.employments.last.employment_roles_employments.create!(
      employment_role_id: employment_roles(:technical_board).id,
      percent: 15
    )

    pablo = employees(:next_year_pablo)
    pablo.update!(department: departments(:devone)) # 100%
    pablo.employments.last.employment_roles_employments.delete_all
    pablo.employments.last.employment_roles_employments.create!(
      employment_role_id: employment_roles(:software_developer).id,
      employment_role_level_id: employment_role_levels(:professional).id,
      percent: 70
    )
    pablo.employments.last.employment_roles_employments.create!(
      employment_role_id: employment_roles(:project_manager).id,
      employment_role_level_id: employment_role_levels(:junior).id,
      percent: 20
    )
    pablo.employments.last.employment_roles_employments.create!(
      employment_role_id: employment_roles(:technical_board).id,
      percent: 10
    )

    john = employees(:long_time_john)
    john.update!(department: departments(:devtwo)) # 90%
    john.employments.last.employment_roles_employments.delete_all
    john.employments.last.employment_roles_employments.create!(
      employment_role_id: employment_roles(:ux_consultant).id,
      employment_role_level_id: employment_role_levels(:professional).id,
      percent: 90
    )
  end
end
