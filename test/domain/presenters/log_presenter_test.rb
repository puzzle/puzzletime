#  Copyright (c) 2006-2022, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class LogPresenterTest < ActiveSupport::TestCase
  test 'title_for_version' do
    employment = Employment.first
    version = PaperTrail::Version.new(
     item_type: "Employment",
     item_id: employment.id,
     event: "destroy"
    )

    assert_equal I18n.t("version.model.destroy.employment", id: employment.id), LogPresenter.new(Employee.new).title_for(version)
  end

  test 'title_for_employmentrolesemployment_version if object record exists' do
    entry = EmploymentRolesEmployment.first
    role = entry.employment_role
    version = PaperTrail::Version.new(
      item_type: "EmploymentRolesEmployment",
      item_id: entry.id,
      event: "destroy"
    )

    assert_equal I18n.t("version.model.destroy.employmentrolesemployment", role: role, employment_id: entry.employment_id), LogPresenter.new(Employee.new).title_for(version)
  end

  test 'title_for_employmentrolesemployment_version if object record does not exist' do
    version = PaperTrail::Version.new(
      item_type: "EmploymentRolesEmployment",
      item_id: 999,
      object: "---\nemployment_id: 999\nemployment_role_id: 999\nemployment_role_level_id: 1\npercent: !ruby/object:BigDecimal 18:0.1e3\n",
      event: "destroy"
      )

    assert_equal I18n.t("version.model.destroy.employmentrolesemployment", role: '(deleted)', employment_id: 999), LogPresenter.new(Employee.new).title_for(version)
  end

end
