#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Invoicing
  module SmallInvoice
    class Api
      include Singleton

      HTTP_TIMEOUT = 300 # seconds
      LIST_PAGES_LIMIT = 100
      LIST_ENTRIES = 200 # the v2 api allows max 200 entries per page

      def list(path, **params)
        # The v2 api returns max 200 entries per query, so we loop through all pages and collect the result.
        (0..LIST_PAGES_LIMIT).each_with_object([]) do |index, result|
          response = get_json(path, **params.reverse_merge(limit: LIST_ENTRIES, offset: LIST_ENTRIES * index))
          result.append(*response['items'])

          return result unless response.dig('pagination', 'next')
        end
      end

      def get(path, **params)
        response = get_json(path, **params)
        response.fetch('item')
      end

      def add(path, data)
        response = post_json(path, **data)
        response.fetch('item')
      end

      def edit(path, data)
        put_json(path, **data)
        nil
      end

      def delete(path)
        delete_request(path)
        nil
      end

      def get_raw(path, auth: true, **params)
        get_request(path, auth: auth, **params).body
      end

      private

      def access_token
        # fetch a new token if we have none yet or if the existing one is expired
        @access_token, @expires_at = get_access_token unless @expires_at&.>(Time.zone.now)
        @access_token
      end

      # Get a new access token from the smallinvoice api.
      # Returns an array with the access_token and the expiration time of this token.
      def get_access_token
        timestamp = Time.zone.now

        response = post_json(
          'auth/access-tokens',
          auth: false,
          grant_type: 'client_credentials',
          client_id: settings.client_id,
          client_secret: settings.client_secret,
          scope: 'invoice contact'
        )

        response.fetch_values('access_token', 'expires_in').yield_self do |token, expires_in|
          [token, timestamp + expires_in]
        end
      end

      def get_json(path, auth: true, **params)
        response = get_request(path, auth: auth, **params)
        handle_json_response(response)
      end

      def get_request(path, auth: true, **params)
        url = build_url(path, **params)
        request = Net::HTTP::Get.new(url.request_uri)
        request['Authorization'] = "Bearer #{access_token}" if auth

        http(url).request(request)
      end

      def post_json(path, auth: true, **payload)
        response = post_request(path, payload.to_json, auth: auth)
        handle_json_response(response)
      end

      def post_request(path, data, auth: true)
        url = build_url(path)
        request = Net::HTTP::Post.new(url,
                                      'Content-Type' => 'application/json')
        request['Authorization'] = "Bearer #{access_token}" if auth
        request.body = data

        http(url).request(request)
      end

      def put_json(path, auth: true, **payload)
        response = put_request(path, payload.to_json, auth: auth)
        handle_json_response(response)
      end

      def put_request(path, data, auth: true)
        url = build_url(path)
        request = Net::HTTP::Put.new(url,
                                     'Content-Type' => 'application/json')
        request['Authorization'] = "Bearer #{access_token}" if auth
        request.body = data

        http(url).request(request)
      end

      def delete_request(path, auth: true)
        url = build_url(path)
        request = Net::HTTP::Delete.new(url,
                                        'Content-Type' => 'application/json')
        request['Authorization'] = "Bearer #{access_token}" if auth

        http(url).request(request)
      end

      def http(url)
        Net::HTTP.new(url.host, url.port).tap do |http|
          http.use_ssl = url.scheme == 'https'
          http.read_timeout = HTTP_TIMEOUT
        end
      end

      def build_url(path, **params)
        url = [settings.url, path].join('/')
        URI.parse(url).tap do |url|
          url.query = URI.encode_www_form(params) if params.present?
        end
      end

      def handle_json_response(response)
        handle_error(response) unless response.is_a? Net::HTTPSuccess

        return {} if response.body.blank?

        parse_json_response(response)
      end

      def handle_error(response)
        payload = parse_json_response(response)
        fail Invoicing::Error.new(response.message, response.code, payload)
      end

      def parse_json_response(response)
        JSON.parse(response.body)
      rescue JSON::ParserError
        fail Invoicing::Error.new('JSON::ParserError', response.code, response.body)
      end

      def settings
        Settings.small_invoice
      end
    end
  end
end
