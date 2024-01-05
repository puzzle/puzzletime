#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'
require 'zxing'

class EmployeeMasterDataControllerTest < ActionController::TestCase
  def setup
    login

    employees(:various_pedro).update(
      birthday: Date.parse('4.2.1942'),
      street: 'Belpstrasse 7',
      postal_code: 3007,
      city: 'Bern',
      phone_office: '0310000000',
      phone_private: '0780000000'
    )
  end

  test 'GET index' do
    get :index
    assert_equal %w(Pedro John Pablo), assigns(:employees).map(&:firstname)
  end

  test 'GET index excludes employees not employed today' do
    employees(:various_pedro).employments.last.update!(end_date: Time.zone.today - 1.day)
    get :index
    assert_equal %w(John Pablo), assigns(:employees).map(&:firstname)
  end

  test 'GET index with sorting' do
    employees(:long_time_john).update!(department_id: departments(:devone).id)
    employees(:next_year_pablo).update!(department_id: departments(:devtwo).id)
    employees(:various_pedro).update!(department_id: departments(:sys).id)
    get :index, params: { sort: 'department', sort_dir: 'asc' }
    assert_equal %w(John Pablo Pedro), assigns(:employees).map(&:firstname)
  end

  test 'GET index with sorting by last employment' do
    employments(:next_year).tap do |e|
      e.end_date = Date.new(2007, 12, 31)
      e.save!
    end
    Fabricate(:employment,
              employee: employees(:next_year_pablo),
              percent: 100,
              start_date: Date.new(2017, 7, 24),
              end_date: nil)
    get :index, params: { sort: 'latest_employment', sort_dir: 'desc' }
    assert_equal %w(John Pedro Pablo), assigns(:employees).map(&:firstname)
    expected = [Date.new(1990, 1, 1), Date.new(2005, 11, 1), Date.new(2017, 7, 24)]
    actual = assigns(:employees).map do |e|
      assigns(:employee_employment)[e]
    end
    assert_equal expected, actual
  end

  test 'GET index with searching' do
    get :index, params: { q: 'ped' }
    assert_equal %w(Pedro), assigns(:employees).map(&:firstname)
  end

  test 'GET show' do
    get :show, params: { id: employees(:various_pedro).id }
    assert_equal employees(:various_pedro), assigns(:employee)
  end

  test 'GET show vcard' do
    get :show, params: { id: employees(:various_pedro).id }, format: :vcf
    assert_equal employees(:various_pedro), assigns(:employee)

    expected = <<~VCF
      BEGIN:VCARD
      VERSION:3.0
      N:Dolores;Pedro;;;
      FN:Pedro Dolores
      ADR;TYPE=HOME,PREF:;;Belpstrasse 7;Bern;;3007;
      TEL;TYPE=WORK,VOICE:0310000000
      TEL;TYPE=CELL,PREF,VOICE:0780000000
      EMAIL;TYPE=WORK,PREF:bol@bla.ch
      BDAY:19420204
      END:VCARD
    VCF
    assert_equal expected, response.body
  end

  test 'GET show png' do
    get :show, params: { id: employees(:various_pedro).id }, format: :png

    expected = <<~VCF
      BEGIN:VCARD
      VERSION:3.0
      N:Dolores;Pedro;;;
      FN:Pedro Dolores
      TEL;TYPE=WORK,VOICE:0310000000
      TEL;TYPE=CELL,PREF,VOICE:0780000000
      EMAIL;TYPE=WORK,PREF:bol@bla.ch
      END:VCARD
    VCF

    require 'zxing'
    assert_equal expected, ZXing.decode!(response.body)
  end

  test 'GET show svg' do
    get :show, params: { id: employees(:various_pedro).id }, format: :svg

    svg = response.body
    assert_match /<svg version="1.1"/, svg

    # zxing gem can not read svg from string, so we need to write it to a file
    Tempfile.open('svg') do |f|
      f.write(svg)
      f.rewind

      expected = <<~VCF
        BEGIN:VCARD
        VERSION:3.0
        N:Dolores;Pedro;;;
        FN:Pedro Dolores
        TEL;TYPE=WORK,VOICE:0310000000
        TEL;TYPE=CELL,PREF,VOICE:0780000000
        EMAIL;TYPE=WORK,PREF:bol@bla.ch
        END:VCARD
      VCF

      assert_equal expected, ZXing.decode!(f)
    end
  end

  test 'GET show hide classified data to non management' do
    login_as(:next_year_pablo)
    get :show, params: { id: employees(:various_pedro).id }
    refute_match(/AHV-Nummer/, response.body)
  end

  test 'GET show show classified data to responsible' do
    login_as(:lucien)
    get :show, params: { id: employees(:various_pedro).id }
    assert_match(/AHV-Nummer/, response.body)
  end

  test 'GET show show classified data to management' do
    login_as(:half_year_maria)
    get :show, params: { id: employees(:various_pedro).id }
    assert_match(/AHV-Nummer/, response.body)
  end

  test 'GET show show classified data to owner' do
    login_as(:various_pedro)
    get :show, params: { id: employees(:various_pedro).id }
    assert_match(/AHV-Nummer/, response.body)
  end
end
