# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


require 'test_helper'

class Api::V1::EmployeesControllerTest < ActionController::TestCase
  setup do
    request.headers['Authorization'] = basic_auth_header
    request.headers['Accept'] = Mime::Type.lookup_by_extension(:jsonapi).to_s
  end

  test 'show' do
    get :show, params: { id: test_entry.id }
    assert_response :ok
    assert_match %r[\Aapplication/vnd\.api\+json], response.headers['Content-Type']
    assert_equal test_entry.id.to_s, response_json[:data][:id]
  end

  test 'show with unknown includes parameter' do
    get :show, params: { id: employees(:long_time_john).id, include: 'current_employment' }
    assert_response :unprocessable_entity
    assert_match %r[\Aapplication/vnd\.api\+json], response.headers['Content-Type']
    assert_equal '422', response_json.dig(:errors, 0, :status)
    assert_equal 'error', response_json.dig(:errors, 0, :code)
    assert_match /current_employment is not specified as a relationship/, response_json.dig(:errors, 0, :title)
  end

  test 'index' do
    get :index
    assert_response :ok
    assert_match %r[\Aapplication/vnd\.api\+json], response.headers['Content-Type']
    assert_equal Employee.count, response_json[:data].count
  end

  test 'index with scope parameter' do
    get :index, params: { scope: :current }
    assert_response :ok
    assert_match %r[\Aapplication/vnd\.api\+json], response.headers['Content-Type']
    assert_equal Employee.current.count, response_json[:data].count
  end

  (1..3).each do |i|
    test "pagination per_page works with #{i}" do
      get :index, params: { per_page: i }
      assert_equal i, response_json[:data].count
    end

    test "pagination page works with #{i}" do
      get :index, params: { page: i }
      expected = Employee.list.page(i).pluck(:id)
      actual   = response_json[:data].map { |d| d[:id].to_i }
      assert_equal expected, actual
    end
  end

  test "pagination headers are present" do
    get :index, params: { page: 2, per_page: 1 }
    list_entries = Employee.list.page(2).per(1)

    assert_equal list_entries.total_count,      response.headers['PaginationTotalCount']
    assert_equal list_entries.current_per_page, response.headers['PagionationPerPage']
    assert_equal list_entries.current_page,     response.headers['PaginationCurrentPage']
    assert_equal list_entries.total_pages,      response.headers['PaginationTotalPages']
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
