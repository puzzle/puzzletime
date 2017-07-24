module CrmHelper

  def crm_order_link(order, label = nil)
    crm_link(Crm.instance.order_url(order), label)
  end

  def crm_contact_link(contact, label = nil)
    crm_link(Crm.instance.contact_url(contact), label)
  end

  def crm_client_link(client, label = nil)
    crm_link(Crm.instance.client_url(client), label)
  end

  def crm_link(url, label)
    return unless url

    link_to(url, target: '_blank', rel: 'noopener noreferrer') do
      content = []
      content << image_tag(Crm.instance.icon) if Crm.instance.icon
      content << (label.presence || Crm.instance.name)
      safe_join(content, ' ')
    end
  end

end