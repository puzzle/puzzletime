# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


require 'test_helper'

module Jsonapi
  class EmployeesControllerTest < ActionController::TestCase
    tests EmployeesController

    setup do
      request.headers['Authorization'] = basic_auth_header
      request.headers['Accept'] = Mime::Type.lookup_by_extension(:jsonapi).to_s
    end

    test 'jsonapi show' do
      get :show, params: { id: test_entry.id }
      assert_response :ok
      assert_match %r[\Aapplication/vnd\.api\+json], response.headers['Content-Type']
      assert_equal test_entry.id.to_s, response_json[:data][:id]
    end

    test 'jsonapi show with fields parameter' do
      get :show, params: { id: test_entry.id, 'fields[employee]' => 'firstname' }
      assert_response :ok
      assert_match %r[\Aapplication/vnd\.api\+json], response.headers['Content-Type']
      assert_arrays_match ['firstname'], response_json[:data][:attributes].keys
    end

    test 'jsonapi show with includes parameter' do
      get :show, params: { id: employees(:long_time_john).id, include: 'current_employment' }
      assert_response :ok
      assert_match %r[\Aapplication/vnd\.api\+json], response.headers['Content-Type']
      assert_equal 'employment', response_json[:included].first[:type]
      assert_equal test_entry.current_employment.id.to_s, response_json[:included].first[:id]
    end

    test 'jsonapi index' do
      get :index
      assert_response :ok
      assert_match %r[\Aapplication/vnd\.api\+json], response.headers['Content-Type']
      assert_equal Employee.count, response_json[:data].count
    end

    test 'jsonapi index with scope parameter' do
      get :index, params: { scope: :current }
      assert_response :ok
      assert_match %r[\Aapplication/vnd\.api\+json], response.headers['Content-Type']
      assert_equal Employee.current.count, response_json[:data].count
    end

    private

    def basic_auth_header
      encoded_credentials = Base64.strict_encode64("#{Settings.api_client.user}:#{Settings.api_client.password}")
      "Basic #{encoded_credentials}"
    end

    # Test object used in several tests.
    def test_entry
      @test_entry ||= employees(:long_time_john)
    end

    def response_json
      ActiveSupport::HashWithIndifferentAccess.new(JSON.parse(response.body))
    end
  end
end
