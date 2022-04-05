#  Copyright (c) 2006-2022, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class ContactTest < ActiveSupport::TestCase
  def contact(email:)
    Fabricate.build(:contact, email: email, client: clients(:puzzle))
  end

  test 'email can be blank' do
    assert contact(email: nil).valid?
    assert contact(email: '').valid?
  end

  test 'email must be valid' do
    assert contact(email: 'test.email+tag@example.com').valid?
    refute contact(email: 'test').valid?
    refute contact(email: 'example.com').valid?
    refute contact(email: '@example.com').valid?
    refute contact(email: 'test@email@example.com').valid?
    refute contact(email: 'andré@example.com').valid?
  end
end
