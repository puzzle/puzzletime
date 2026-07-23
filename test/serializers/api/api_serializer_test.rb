# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

module Api
  class ApiSerializerTest < ActiveSupport::TestCase
    # A missing annotation crashes the api doc generation, so every serialized
    # attribute must be annotated.
    test 'every serialized attribute is annotated for the api docs' do
      Rails.application.eager_load!

      Api::ApiSerializer.descendants.each do |serializer|
        serializer.attributes_to_serialize.each_key do |attr|
          assert serializer.annotated?(attr),
                 "#{serializer} is missing an api doc annotation for :#{attr}"
        end
      end
    end
  end
end
