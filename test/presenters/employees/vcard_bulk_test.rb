# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

module Employees
  class VcardBulkTest < ActiveSupport::TestCase
    def employee(**attrs)
      Employee.new(attrs.reverse_merge(
                     firstname: 'Erika',
                     lastname: 'Musterfrau',
                     email: 'emuster@example.com'
                   ))
    end

    test 'renders concatenated vcards for all given employees' do
      employees = [
        employee(firstname: 'Erika', lastname: 'Musterfrau'),
        employee(firstname: 'Max', lastname: 'Mustermann')
      ]

      expected = <<~VCF
        BEGIN:VCARD
        VERSION:3.0
        N:Musterfrau;Erika;;;
        FN:Erika Musterfrau
        EMAIL;TYPE=WORK,PREF:emuster@example.com
        END:VCARD
        BEGIN:VCARD
        VERSION:3.0
        N:Mustermann;Max;;;
        FN:Max Mustermann
        EMAIL;TYPE=WORK,PREF:emuster@example.com
        END:VCARD
      VCF

      assert_equal expected, Employees::VcardBulk.new(employees).render
    end

    test 'renders nothing for an empty list' do
      assert_equal '', Employees::VcardBulk.new([]).render
    end
  end
end
