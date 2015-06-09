module Invoicing
  module SmallInvoice
    class Api

      include Singleton

      ENDPOINTS = %w(invoice client)

      def list(endpoint)
        response = get_request(endpoint, :list)
        response['items']
      end

      def get(endpoint, id)
        response = get_request(endpoint, :get, id: id)
        response['item']
      end

      def add(endpoint, data)
        response = post_request(endpoint, :add, data)
        response['id']
      end

      def edit(endpoint, id, data)
        post_request(endpoint, :edit, data, id: id)
        nil
      end

      def delete(endpoint, id)
        post_request(endpoint, :delete, nil, id: id)
        nil
      end

      private

      def get_request(endpoint, action, params = {})
        response = Net::HTTP.get_response(uri(endpoint, action, params))
        handle_response(response)
      end

      def post_request(endpoint, action, data, params = {})
        url = uri(endpoint, action, params)
        body = data ? { data: data.to_json } : {}
        response = Net::HTTP.post_form(url, body)
        handle_response(response)
      end

      def uri(endpoint, action, params = {})
        fail(ArgumentError, "Unknown endpoint #{endpoint}") unless ENDPOINTS.include?(endpoint.to_s)

        params[:token] = Settings.small_invoice.api_token
        args = params.collect { |k, v| "#{k}/#{v}" }.join('/')
        URI("#{Settings.small_invoice.url}/#{endpoint}/#{action}/#{args}")
      end

      def handle_response(response)
        json = JSON.parse(response.body)
        if json['error']
          fail Invoicing::Error.new(json['errormessage'], json['errorcode'])
        else
          json
        end
      end
    end
  end
end
