# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

module Plannings
  class CompanyNotesControllerTest < ActionController::TestCase
    setup :login

    test 'GET#show renders note as markdown' do
      employees(:pascal).update!(planning_note: '**fett**')

      get :show, params: { id: employees(:pascal).id }, format: :js

      assert_response :success
      assert_includes @response.body, '<strong>fett</strong>'
    end

    test 'GET#show does not render raw script tags' do
      employees(:pascal).update!(planning_note: "<script>alert('x')</script>")

      get :show, params: { id: employees(:pascal).id }, format: :js

      assert_response :success
      assert_no_match(/<script/, @response.body)
    end

    test 'GET#edit as management shows markdown source form' do
      get :edit, params: { id: employees(:pascal).id }, format: :js

      assert_response :success
      assert_includes @response.body, 'textarea'
    end

    test 'GET#edit as order responsible shows form' do
      login_as(:lucien)

      get :edit, params: { id: employees(:pascal).id }, format: :js

      assert_response :success
    end

    test 'GET#edit as regular user is denied' do
      login_as(:pascal)

      assert_raises(CanCan::AccessDenied) do
        get :edit, params: { id: employees(:lucien).id }, format: :js
      end
    end

    test 'PATCH#update as management updates planning note and returns filled icon' do
      patch :update,
            params: { id: employees(:pascal).id, employee: { planning_note: 'Neue Notiz' } },
            format: :js

      assert_response :success
      assert_equal 'Neue Notiz', employees(:pascal).reload.planning_note
      assert_includes @response.body, 'has-note'
    end

    test 'PATCH#update as order responsible updates planning note' do
      login_as(:lucien)
      patch :update,
            params: { id: employees(:pascal).id, employee: { planning_note: 'AV Notiz' } },
            format: :js

      assert_response :success
      assert_equal 'AV Notiz', employees(:pascal).reload.planning_note
    end

    test 'PATCH#update as regular user is denied' do
      login_as(:pascal)
      assert_raises(CanCan::AccessDenied) do
        patch :update,
              params: { id: employees(:lucien).id, employee: { planning_note: 'Nope' } },
              format: :js
      end
      assert_nil employees(:lucien).reload.planning_note
    end

    test 'PATCH#update saves note longer than 255 characters' do
      long_note = 'x' * 300

      patch :update,
            params: { id: employees(:pascal).id, employee: { planning_note: long_note } },
            format: :js

      assert_response :success
      assert_equal long_note, employees(:pascal).reload.planning_note
    end
  end
end
