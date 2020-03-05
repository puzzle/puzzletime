class ApiClient
  def authenticate(user, password)
    return self if Settings.api_client.user == user && Settings.api_client.password == password
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
