# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

module Apidocs
  class SetupTest < ActiveSupport::TestCase
    # index_path/show_path rescue to nil, so a broken route silently drops the
    # operation from the docs. Guard that the operations actually show up.
    test 'documents index and show operations for every api controller' do
      doc = Setup.new('v1', 'http://example.com/api/docs/v1', api_controllers).run

      api_controllers.each do |controller|
        route = controller.model_class.model_name.route_key

        assert doc[:paths].key?(:"/api/v1/#{route}"), "missing index operation for #{controller}"
        assert doc[:paths].key?(:"/api/v1/#{route}/{id}"), "missing show operation for #{controller}"
      end
    end

    # param_annotations must not leak between controllers (shared class_attribute trap).
    test 'documents only the controller’s own query params' do
      doc = Setup.new('v1', 'http://example.com/api/docs/v1', api_controllers).run
      params = doc[:paths][:'/api/v1/orders'][:get][:parameters].map { |p| p[:name] }

      assert_includes params, 'filter[email]'
      assert_not_includes params, :scope, 'scope belongs to employees, not orders'
    end

    # Every includable relationship (incl. transitively-related ones) must be
    # documented as a component schema and referenced in the `included` oneOf,
    # else clients get undocumented objects back when they use ?include=.
    test 'documents all includable relationships in the included oneOf' do
      doc = Setup.new('v1', 'http://example.com/api/docs/v1', api_controllers).run
      one_of = doc.dig(:paths, :'/api/v1/orders', :get, :responses, 200,
                       :content, 'application/vnd.api+json', :schema,
                       :properties, :included, :items, :oneOf)
      refs = one_of.map { |schema| schema['$ref'] }

      assert_includes refs, '#/components/schemas/Employee'
      assert_includes refs, '#/components/schemas/AdditionalCrmOrder'
    end

    private

    def api_controllers
      Rails.application.eager_load!
      Api::JsonapiController.descendants.select do |controller|
        controller.name.to_s.include?('Api::V1') && controller.model_class
      rescue NameError
        false
      end
    end
  end
end
