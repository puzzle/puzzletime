module Devise
  module Strategies
    # The API Strategy is responsible for authenticating calls to the /api/vx/ endpoint.
    # :reek:MissingSafeMethod { exclude: [ authenticate! ] }
    class API < Base
      def store?
        false
      end

      def valid?
        user, pass = ActionController::HttpAuthentication::Basic.user_name_and_password(request)
        user && pass && request.path.match?(%r{^/api/v\d+/})
      end

      def authenticate!
        user = user_from_basic_auth

        if user.is_a? ApiClient
          success!(user)
        else
          fail('Could not login with API Credentials') # rubocop:disable Style/SignalException
        end
      end

      private

      def user_from_basic_auth
        request
          .controller_instance
          .authenticate_or_request_with_http_basic('Puzzletime') do |user, password|
            ApiClient.new.authenticate(user, password)
          end
      end
    end
  end
end
