module ClientsHelper
  def format_client_crm_key(client)
    crm_client_link(client, client.crm_key)
  end
end
