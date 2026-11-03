# frozen_string_literal: true

#  Copyright (c) 2006-2025, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

module Crm
  class Odoo
    class PartnerTest < ActiveSupport::TestCase
      setup do
        @api = mock('api')
        Crm.instance = stub(api: @api)
      end

      teardown do
        Crm.instance = nil
      end

      test 'optional fields follow an odoo upgrade without a restart' do
        @api.stubs(:fields_get).returns(odoo_fields(*%w[id name mobile]), odoo_fields(*%w[id name phone2]))
        requested = []
        @api.stubs(:search_read).with { |_m, options:, **| requested << options[:fields] }.returns([])

        2.times { Partner.all }

        assert_includes requested.first, :mobile
        assert_not_includes requested.first, :phone2
        assert_includes requested.last, :phone2
        assert_not_includes requested.last, :mobile
      end

      test 'mobile is neither requested nor set when odoo does not have the field' do
        stub_odoo(fields: %w[id name phone], row: { 'id' => 1, 'name' => 'Ann Odoo', 'phone' => '+41 79 1' }) do |fields|
          assert_not_includes fields, :mobile
        end

        partner = Partner.all(options: {}).first

        assert_not partner.attribute?(:mobile)
        assert_nil partner.mobile
        assert_not_includes Crm::Odoo.new.send(:contact_attributes, partner), :mobile
      end

      test 'mobile is requested and set once odoo has the field' do
        stub_odoo(fields: %w[id name phone mobile],
                  row: { 'id' => 1, 'name' => 'Ann Odoo', 'phone' => '+41 31 1', 'mobile' => '+41 79 1' }) do |fields|
          assert_includes fields, :mobile
        end

        partner = Partner.all(options: {}).first

        assert partner.attribute?(:mobile)
        assert_equal '+41 79 1', Crm::Odoo.new.send(:contact_attributes, partner)[:mobile]
      end

      test 'mobile cleared in odoo is passed on as nil once the field is available' do
        stub_odoo(fields: %w[id name phone mobile],
                  row: { 'id' => 1, 'name' => 'Ann Odoo', 'mobile' => false }) { nil }

        attrs = Crm::Odoo.new.send(:contact_attributes, Partner.all(options: {}).first)

        assert_includes attrs, :mobile
        assert_nil attrs[:mobile]
      end

      test 'mobile is taken from phone2 on odoo versions without mobile' do
        stub_odoo(fields: %w[id name phone phone2],
                  row: { 'id' => 1, 'name' => 'Ann Odoo', 'phone2' => '+41 79 2' }) do |fields|
          assert_includes fields, :phone2
          assert_not_includes fields, :mobile
        end

        attrs = Crm::Odoo.new.send(:contact_attributes, Partner.all(options: {}).first)

        assert_equal '+41 79 2', attrs[:mobile]
      end

      test 'mobile is preferred over phone2 when both are available' do
        stub_odoo(fields: %w[id name phone mobile phone2],
                  row: { 'id' => 1, 'name' => 'Ann Odoo', 'mobile' => '+41 79 1', 'phone2' => '+41 79 2' }) { nil }

        attrs = Crm::Odoo.new.send(:contact_attributes, Partner.all(options: {}).first)

        assert_equal '+41 79 1', attrs[:mobile]
      end

      private

      # yields the fields requested from search_read for assertions
      def stub_odoo(fields:, row:)
        @api.stubs(:fields_get).returns(fields.index_with { {} })
        @api.expects(:search_read).with do |_model, parameters:, options:|
          yield options[:fields]
          parameters.present?
        end.returns([row])
      end

      def odoo_fields(*fields)
        fields.index_with { {} }
      end
    end
  end
end
