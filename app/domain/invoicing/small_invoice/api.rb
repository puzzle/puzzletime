module Invoicing
  module SmallInvoice
    class Api
      include Singleton

      ENDPOINTS = %w(invoice invoice/pdf client)

      def list(endpoint)
        response = get_json(endpoint, :list)
        response['items']
      end

      def get(endpoint, id)
        response = get_json(endpoint, :get, id: id)
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

      def get_raw(endpoint, action, id)
        get_request(endpoint, action, id: id).body
      end

      private

      def get_json(endpoint, action, params = {})
        response = get_request(endpoint, action, params)
        handle_json_response(response)
      end

      def get_request(endpoint, action, params = {})
        url = uri(endpoint, action, params)
        request = Net::HTTP::Get.new(url.path)
        http(url).request(request)
      end

      def post_request(endpoint, action, data, params = {})
        url = uri(endpoint, action, params)
        request = Net::HTTP::Post.new(url.path)
        request.set_form_data(data ? { data: data.to_json } : {})

        response = http(url).request(request)
        handle_json_response(response)
      end

      def http(url)
        Net::HTTP.new(url.host, url.port).tap { |http| http.use_ssl = url.scheme == 'https' }
      end

      def uri(endpoint, action, params = {})
        fail(ArgumentError, "Unknown endpoint #{endpoint}") unless ENDPOINTS.include?(endpoint.to_s)

        params[:token] = Settings.small_invoice.api_token
        args = params.collect { |k, v| "#{k}/#{v}" }.join('/')
        URI("#{Settings.small_invoice.url}/#{endpoint}/#{action}/#{args}")
      end

      def handle_json_response(response)
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
