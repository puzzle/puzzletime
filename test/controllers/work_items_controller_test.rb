# frozen_string_literal: true

#  Copyright (c) 2006-2019, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class WorkItemsControllerTest < ActionController::TestCase
  setup :login

  def test_search
    work_item = work_items(:hitobito_demo_app)
    get :search, params: { q: work_item.path_shortnames }, format: :json

    assert find_in_body(response.body, 'id', work_item.id)
  end

  private

  def find_in_body(body, field, element)
    JSON.parse(body).find { |w| w[field] == element }
  end
end
