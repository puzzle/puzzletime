#  Copyright (c) 2006-2023, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class Employees::VcardTest < ActiveSupport::TestCase
  def vcard(employee, include: nil)
    Employees::Vcard.new(employee, include:).render
  end

  def employee(**attrs)
    Employee.new(attrs.reverse_merge(
                   firstname: 'Erika',
                   lastname: 'Musterfrau',
                   email: 'emuster@example.com',
                   street: 'Belpstrasse 7',
                   postal_code: 3007,
                   city: 'Bern',
                   phone_office: '0310000000',
                   phone_private: '0780000000',
                   birthday: Date.parse('1.1.1942')
                 ))
  end

  test 'renders vcard for employee' do
    expected = <<~VCF
      BEGIN:VCARD
      VERSION:3.0
      N:Musterfrau;Erika;;;
      FN:Erika Musterfrau
      ADR;TYPE=HOME,PREF:;;Belpstrasse 7;Bern;;3007;
      TEL;TYPE=WORK,VOICE:0310000000
      TEL;TYPE=CELL,PREF,VOICE:0780000000
      EMAIL;TYPE=WORK,PREF:emuster@example.com
      BDAY:19420101
      END:VCARD
    VCF

    assert_equal expected, vcard(employee)
  end

  test 'renders vcard when employee attrs are blank' do
    expected = <<~VCF
      BEGIN:VCARD
      VERSION:3.0
      N:;Tester;;;
      FN:Tester
      EMAIL;TYPE=WORK,PREF:
      END:VCARD
    VCF

    assert_equal expected, vcard(Employee.new(firstname: 'Tester'))
  end

  test 'renders vcard with specified attrs' do
    expected = <<~VCF
      BEGIN:VCARD
      VERSION:3.0
      N:;Erika;;;
      FN:Erika
      TEL;TYPE=CELL,PREF,VOICE:0780000000
      EMAIL;TYPE=WORK,PREF:
      BDAY:19420101
      END:VCARD
    VCF

    assert_equal expected, vcard(employee, include: [
                                   :firstname, :phone_private, :birthday
                                 ])
  end
end
