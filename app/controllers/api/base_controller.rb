#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


module Api
  class BaseController < ManageController
    def index
      render json: serializer.new(entries).serializable_hash
    end

    def show
      render json: serializer.new(entry).serializable_hash
    end

    private

    def entries
      super.map {|entry| Api::Employee.new(entry) }
    end

    # def model_class
    #   @model_class ||= "Api::#{controller_name.classify}".constantize
    # end

    def serializer_class_name
      "Api::#{model_class.name}Serializer"
    end

    def serializer
      serializer_class_name.constantize
    end
  end
end