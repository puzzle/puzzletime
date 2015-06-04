module Invoicing
  class SmallInvoice
    class Api

      def list(endpoint)
        response = get_request("#{endpoint}/list")
        response['items']
      end

      def get(endpoint, id)
        response = get_request("#{endpoint}/get", id: id)
        response['item']
      end

      def add(endpoint, body)
        response = post_request("#{endpoint}/add", body)
        response['id']
      end

      def edit(endpoint, id, body)
        post_request("#{endpoint}/edit", body, id: id)
        nil
      end

      private

      def get_request(path, params = {})
        response = Net::HTTP.get_response(uri(path, params))
        handle_response(response)
      end

      def post_request(path, body, params = {})
        response = Net::HTTP.post_form(uri(path, params), data: body.to_json)
        handle_response(response)
      end

      def uri(path, params = {})
        params[:token] = Settings.small_invoice.api_token
        args = params.collect { |k, v| "#{k}/#{v}" }.join('/')
        URI("#{Settings.small_invoice.url}/#{path}/#{args}")
      end

      def handle_response(response)
        json = JSON.parse(response.body)
        if json['error']
          fail Invoicing::Error, "#{json['errormessage']} (#{json['errorcode']})"
        else
          json
        end
      end

    end
  end
end
