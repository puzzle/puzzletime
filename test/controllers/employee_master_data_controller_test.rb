# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

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

    assert_equal %w[Pedro John Pablo], assigns(:employees).map(&:firstname)
  end

  test 'GET index excludes employees not employed today' do
    employees(:various_pedro).employments.last.update!(end_date: Time.zone.today - 1.day)
    get :index

    assert_equal %w[John Pablo], assigns(:employees).map(&:firstname)
  end

  test 'GET index with sorting' do
    employees(:long_time_john).update!(department: departments(:devone))
    employees(:next_year_pablo).update!(department: departments(:devtwo))
    employees(:various_pedro).update!(department: departments(:sys))
    get :index, params: { sort: 'department', sort_dir: 'asc' }

    assert_equal %w[John Pablo Pedro], assigns(:employees).map(&:firstname)
  end

  test 'GET index with sorting by member_coach' do
    employees(:long_time_john).update!(member_coach: employees(:pascal))
    employees(:next_year_pablo).update!(member_coach: employees(:mark))
    employees(:various_pedro).update!(member_coach: employees(:lucien))
    get :index, params: { sort: 'member_coach', sort_dir: 'asc' }

    assert_equal(%w[Mark Lucien Pascal], assigns(:employees).map { |e| e.member_coach.firstname })

    get :index, params: { sort: 'member_coach', sort_dir: 'desc' }

    assert_equal(%w[Pascal Lucien Mark], assigns(:employees).map { |e| e.member_coach.firstname })
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

    assert_equal %w[John Pedro Pablo], assigns(:employees).map(&:firstname)
    expected = [Date.new(1990, 1, 1), Date.new(2005, 11, 1), Date.new(2017, 7, 24)]
    actual = assigns(:employees).map do |e|
      assigns(:employee_employment)[e]
    end

    assert_equal expected, actual
  end

  test 'GET index with searching' do
    get :index, params: { q: 'ped' }

    assert_equal %w[Pedro], assigns(:employees).map(&:firstname)
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

    expected = RQRCode::QRCode.new(<<~VCF).as_png(fill: 'fff')
      BEGIN:VCARD
      VERSION:3.0
      N:Dolores;Pedro;;;
      FN:Pedro Dolores
      TEL;TYPE=WORK,VOICE:0310000000
      TEL;TYPE=CELL,PREF,VOICE:0780000000
      EMAIL;TYPE=WORK,PREF:bol@bla.ch
      END:VCARD
    VCF

    assert_equal expected.to_blob, response.body
  end

  test 'GET show svg' do
    get :show, params: { id: employees(:various_pedro).id }, format: :svg

    svg = response.body

    expected = RQRCode::QRCode.new(<<~VCF).as_svg(fill: 'fff')
      BEGIN:VCARD
      VERSION:3.0
      N:Dolores;Pedro;;;
      FN:Pedro Dolores
      TEL;TYPE=WORK,VOICE:0310000000
      TEL;TYPE=CELL,PREF,VOICE:0780000000
      EMAIL;TYPE=WORK,PREF:bol@bla.ch
      END:VCARD
    VCF

    assert_match(/<svg version="1.1"/, svg)
    assert_equal expected, svg
  end

  test 'GET vcards returns vcard for every employed employee' do
    get :vcards

    assert_equal 'text/vcard', response.headers['Content-Type']
    assert_equal 'attachment; filename="Kontakte_Alle.vcf"; filename*=UTF-8\'\'Kontakte_Alle.vcf',
                 response.headers['Content-Disposition']
    assert_equal 3, response.body.scan('BEGIN:VCARD').count
    assert_match(/FN:Pedro Dolores/, response.body)
    assert_match(/FN:John Neverends/, response.body)
    assert_match(/FN:Pablo Sanchez/, response.body)
  end

  test 'GET vcards treats a blank department_id like no filter' do
    get :vcards, params: { department_id: '' }

    assert_equal 3, response.body.scan('BEGIN:VCARD').count
    assert_equal 'attachment; filename="Kontakte_Alle.vcf"; filename*=UTF-8\'\'Kontakte_Alle.vcf',
                 response.headers['Content-Disposition']
  end

  test 'GET vcards renders employees with missing optional attributes correctly' do
    get :vcards

    expected_pedro = <<~VCF
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

    expected_pablo = <<~VCF
      BEGIN:VCARD
      VERSION:3.0
      N:Sanchez;Pablo;;;
      FN:Pablo Sanchez
      EMAIL;TYPE=WORK,PREF:ps@bla.ch
      END:VCARD
    VCF

    assert_includes response.body, expected_pedro
    assert_includes response.body, expected_pablo
  end

  test 'GET vcards excludes employees not employed today' do
    employees(:various_pedro).employments.last.update!(end_date: Time.zone.today - 1.day)
    get :vcards

    assert_equal 2, response.body.scan('BEGIN:VCARD').count
    assert_no_match(/FN:Pedro Dolores/, response.body)
  end

  test 'GET vcards filtered by department' do
    employees(:long_time_john).update!(department: departments(:devone))
    employees(:next_year_pablo).update!(department: departments(:devtwo))
    employees(:various_pedro).update!(department: departments(:devtwo))

    get :vcards, params: { department_id: departments(:devtwo).id }

    assert_equal 'attachment; filename="Kontakte_devtwo.vcf"; filename*=UTF-8\'\'Kontakte_devtwo.vcf',
                 response.headers['Content-Disposition']
    assert_equal 2, response.body.scan('BEGIN:VCARD').count
    assert_match(/FN:Pablo Sanchez/, response.body)
    assert_match(/FN:Pedro Dolores/, response.body)
    assert_no_match(/FN:John Neverends/, response.body)
  end

  test 'GET vcards strips slashes from department name in filename' do
    department = departments(:devone)
    department.update!(name: '/dev/ruby')
    employees(:long_time_john).update!(department:)

    get :vcards, params: { department_id: department.id }

    assert_equal 'attachment; filename="Kontakte_devruby.vcf"; filename*=UTF-8\'\'Kontakte_devruby.vcf',
                 response.headers['Content-Disposition']
  end

  test 'GET vcards replaces other unsafe characters in department name with a dash' do
    department = departments(:devone)
    department.update!(name: 'Dev:Ops')
    employees(:long_time_john).update!(department:)

    get :vcards, params: { department_id: department.id }

    assert_equal 'attachment; filename="Kontakte_Dev-Ops.vcf"; filename*=UTF-8\'\'Kontakte_Dev-Ops.vcf',
                 response.headers['Content-Disposition']
  end

  test 'GET vcards keeps umlauts in department name intact' do
    department = departments(:devone)
    department.update!(name: 'Geschäftsleitung')
    employees(:long_time_john).update!(department:)

    get :vcards, params: { department_id: department.id }

    assert_equal 'attachment; filename="Kontakte_Geschaftsleitung.vcf"; ' \
                 "filename*=UTF-8''Kontakte_Gesch%C3%A4ftsleitung.vcf",
                 response.headers['Content-Disposition']
  end

  test 'GET vcards for a department without employees returns an empty file' do
    get :vcards, params: { department_id: departments(:devtwo).id }

    assert_equal '', response.body
    assert_equal 'attachment; filename="Kontakte_devtwo.vcf"; filename*=UTF-8\'\'Kontakte_devtwo.vcf',
                 response.headers['Content-Disposition']
  end

  test 'GET vcards raises for an unknown department_id' do
    assert_raises(ActiveRecord::RecordNotFound) do
      get :vcards, params: { department_id: 999_999 }
    end
  end

  test 'GET index only lists departments that have employees, sorted by name' do
    # departments(:devtwo) already has employees via fixtures (pascal, lucien)
    employees(:long_time_john).update!(department: departments(:sys))
    employees(:various_pedro).update!(department: departments(:devone))

    get :index

    assert_equal %w[devone devtwo sys], assigns(:departments).map(&:name)
  end

  test 'GET show hide classified data to non management' do
    login_as(:next_year_pablo)
    get :show, params: { id: employees(:various_pedro).id }

    assert_no_match(/AHV-Nummer/, response.body)
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
