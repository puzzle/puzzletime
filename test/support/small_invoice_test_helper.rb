#  Copyright (c) 2006-2020, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module SmallInvoiceTestHelper
  extend ActiveSupport::Concern

  included do
    setup :stub_auth
  end

  BASE_URL = 'https://api.smallinvoice.com/v2'.freeze

  def entity(name)
    "Invoicing::SmallInvoice::Entity::#{name.to_s.singularize.classify}".constantize
  end

  def stub_auth
    stub_request(:post, "#{BASE_URL}/auth/access-tokens")
      .to_return(status: 200, body: auth_body)
  end

  def stub_get_entity(name, **kwargs)
    args = kwargs.reverse_merge(
      {
        params: kwargs[:key] ? nil : '?limit=200&offset=0'
      }
    )
    stub_api_request(:get, name, **args)
  end

  def stub_add_entity(name, **kwargs)
    args = kwargs.reverse_merge(
      {
        body: JSON.generate(new_contact),
        response: single_response(name)
      }
    )

    stub_api_request(:post, name, args)
  end

  def stub_edit_entity(name, **kwargs)
    args = {
      body: JSON.generate(new_contact)
    }.merge(kwargs)

    stub_api_request(:put, name, args)
  end

  def stub_delete_entity(name, **kwargs)
    stub_api_request(:delete, name, **kwargs)
  end

  def path(name, **kwargs)
    key = kwargs[:key]

    if %i[people addresses].include?(name)
      parent = kwargs[:parent] || default_client
      return entity(name).path(parent, invoicing_key: key) if key

      entity(name).path(parent)
    else
      return entity(name).path(invoicing_key: key) if key

      entity(name).path
    end
  end

  def path_url(name, **kwargs)
    path(name, **kwargs).join('/')
  end

  private

  def stub_api_request(method, name, **kwargs)
    key      = kwargs[:key]
    path     = kwargs[:path] || path_url(name, **kwargs)
    params   = kwargs[:params]
    url      = kwargs[:url] || "#{BASE_URL}/#{path}#{params}"
    body     = kwargs[:body]
    response = kwargs[:response]
    response ||= key ? single_response(name) : response(name)

    stub = stub_request(method, url)
    stub = stub.with(body: body) if body
    stub = stub.to_return(status: 200, body: response) if response
    stub
  end

  def new_contact
    entity(:contacts).new(default_client).to_hash
  end

  def default_client
    clients(:puzzle)
  end

  def client_with_key
    default_client.invoicing_key = 1234
    default_client
  end

  def single_response(name)
    response(name.to_s.singularize)
  end

  def response(name)
    file_fixture("small_invoice/#{name}.json").read
  rescue StandardError
    nil
  end

  def id(name)
    data = JSON.parse(
      file_fixture("small_invoice/#{name}.json").read
    )

    return data['items'].first['id'] if data.key? 'items'

    data['item']['id']
  rescue StandardError
    nil
  end

  def auth_body
    JSON.generate(
      {
        access_token: '1234',
        expires_in: 43200,
        token_type: 'Bearer'
      }
    )
  end
end
