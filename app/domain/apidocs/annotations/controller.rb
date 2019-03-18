# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Apidocs
  module Annotations
    module Controller
      extend ActiveSupport::Concern

      Param = Struct.new(:name, :type, :description, :required, :enum)

      included do
        class_attribute :param_annotations,
                        instance_writer: false,
                        default: Hash.new { |hash, key| hash[key] = [] }
      end

      class_methods do
        # Annotate a parameter for the api documentation
        #
        # action - The parameter applies to this controller action
        # name - The parameter name
        # type - Expected data type of the parameter value, see
        #        https://github.com/OAI/OpenAPI-Specification/blob/master/versions/2.0.md#data-types
        # description - Text
        # required - Mark the parameter as required
        # enum - Valid values can be documented with this
        #
        def annotate_param(action, name, type:, description: nil, required: false, enum: nil)
          param_annotations[action.to_sym] << Param.new(name, type, description, required, enum)
        end
      end
    end
  end
end
