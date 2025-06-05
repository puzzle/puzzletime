# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.
# {{{
# == Schema Information
#
# Table name: employees
#
#  id                        :integer          not null, primary key
#  additional_information    :text
#  birthday                  :date
#  city                      :string
#  committed_worktimes_at    :date
#  crm_key                   :string
#  email                     :string(255)      not null
#  emergency_contact_name    :string
#  emergency_contact_phone   :string
#  encrypted_password        :string           default("")
#  eval_periods              :string(3)        is an Array
#  firstname                 :string(255)      not null
#  graduation                :string
#  identity_card_type        :string
#  identity_card_valid_until :date
#  initial_vacation_days     :float
#  lastname                  :string(255)      not null
#  ldapname                  :string(255)
#  management                :boolean          default(FALSE)
#  marital_status            :integer
#  nationalities             :string           is an Array
#  phone_office              :string
#  phone_private             :string
#  postal_code               :string
#  probation_period_end_date :date
#  remember_created_at       :datetime
#  reviewed_worktimes_at     :date
#  shortname                 :string(3)        not null
#  social_insurance          :string
#  street                    :string
#  worktimes_commit_reminder :boolean          default(TRUE), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  department_id             :integer
#  workplace_id              :bigint
#
# Indexes
#
#  chk_unique_name                   (shortname) UNIQUE
#  index_employees_on_department_id  (department_id)
#  index_employees_on_workplace_id   (workplace_id)
#
# }}}

Fabricator(:employee) do
  firstname { Faker::Name.first_name }
  lastname  { Faker::Name.last_name }
  shortname { ('A'..'Z').to_a.shuffle.take(3).join }
  email     { Faker::Internet.email }
end
