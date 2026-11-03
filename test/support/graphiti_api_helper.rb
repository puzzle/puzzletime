# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Helpers for the integration tests of the Graphiti /api/v2.
#
# `response.parsed_body` is not used on purpose: registering a jsonapi encoder with `register_encoder` is global and
# breaks the other :jsonapi tests. A response that comes from a raised exception (403 from CanCan, 404, ...) does not
# commit the one-shot `login_as` login, so log in again before the next request.
module GraphitiApiHelper
  JSONAPI = { 'CONTENT_TYPE' => 'application/vnd.api+json', 'ACCEPT' => 'application/vnd.api+json' }.freeze

  private

  # {data: {type:, id:, attributes:}} as a request body; pass `id` for updates.
  def payload(type, attributes, id = nil)
    { data: { type:, id: id&.to_s, attributes: }.compact }.to_json
  end

  def json_body
    JSON.parse(response.body)
  end

  # Ids (as integers) of the `data` of a GET.
  def ids(path, params = {})
    get path, params:, headers: JSONAPI
    json_body['data'].pluck('id').map(&:to_i)
  end

  def status_of(path)
    get path, headers: JSONAPI
    response.status
  end

  def basic_auth
    { 'Authorization' => ActionController::HttpAuthentication::Basic.encode_credentials(
      Settings.api_client.user, Settings.api_client.password
    ) }
  end
end
