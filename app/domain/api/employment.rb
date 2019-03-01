module Api
  class Employment < BaseModel
    def roles
      decorated_instance.employment
    end
  end
end