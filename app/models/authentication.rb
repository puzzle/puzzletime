# frozen_string_literal: true

#  Copyright (c) 2006-2025, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# == Schema Information
#
# Table name: authentications
#
#  id           :bigint           not null, primary key
#  provider     :string
#  uid          :string
#  token        :string
#  token_secret :string
#  employee_id  :bigint
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class Authentication < ApplicationRecord
  belongs_to :employee
end
