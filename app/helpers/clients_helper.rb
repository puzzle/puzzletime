module ClientsHelper
  def format_client_crm_key(client)
    link_to(client.crm_key, Crm.instance.client_url(client), target: :blank) if client.crm_key?
  end
end
