# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


# == Schema Information
#
# Table name: order_statuses
#
#  id       :integer          not null, primary key
#  name     :string           not null
#  style    :string
#  closed   :boolean          default(FALSE), not null
#  position :integer          not null
#  default  :boolean          default(FALSE), not null
#

Fabricator(:order_status) do
  name { Faker::Hacker.ingverb }
  style { 'success' }
end
