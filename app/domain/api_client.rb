# frozen_string_literal: true

class ApiClient
  def authenticate(user, password)
    self if Settings.api_client.user == user && Settings.api_client.password == password
  end

  def id
    'api_client'
  end

  def management?
    false
  end

  def order_responsible?
    false
  end
end
