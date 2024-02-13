# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Invoicing
  module SmallInvoice
    class Api
      include Singleton

      ENDPOINTS = %w(invoice invoice/pdf client).freeze
      HTTP_TIMEOUT = 300 # seconds

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

      def get_json(endpoint, action, **params)
        response = get_request(endpoint, action, **params)
        handle_json_response(response)
      end

      def get_request(endpoint, action, **params)
        url = uri(endpoint, action, **params)
        request = Net::HTTP::Get.new(url.path)
        http(url).request(request)
      end

      def post_request(endpoint, action, data, **params)
        url = uri(endpoint, action, **params)
        request = Net::HTTP::Post.new(url.path)
        request.set_form_data(data ? { data: data.to_json } : {})

        response = http(url).request(request)
        handle_json_response(response, data)
      end

      def http(url)
        Net::HTTP.new(url.host, url.port).tap do |http|
          http.use_ssl = url.scheme == 'https'
          http.read_timeout = HTTP_TIMEOUT
        end
      end

      def uri(endpoint, action, **params)
        fail(ArgumentError, "Unknown endpoint #{endpoint}") unless ENDPOINTS.include?(endpoint.to_s)

        params[:token] = Settings.small_invoice.api_token
        args = params.collect { |k, v| "#{k}/#{v}" }.join('/')
        URI("#{Settings.small_invoice.url}/#{endpoint}/#{action}/#{args}")
      end

      def handle_json_response(response, data = nil)
        return {} if response.body.blank?

        json = JSON.parse(response.body)
        if json['error']
          fail Invoicing::Error.new(json['errormessage'], json['errorcode'], data)
        else
          json
        end
      rescue JSON::ParserError
        fail Invoicing::Error.new(response.body, response.code, data)
      end
    end
  end
end
