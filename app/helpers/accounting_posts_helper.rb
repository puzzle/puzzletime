# encoding: UTF-8

module AccountingPostsHelper
  def add_accounting_post_link(order)
    link_text = "#{picon('add')} Buchungsposition hinzufügen".html_safe
    if order.booked_on_order?
      content_tag(:a, link_text, {
          class: 'forbidden',
          title: 'Bestehende "Direkt auf Auftrag buchen" Position muss zuerst in separate Buchungsposition konvertiert werden.'
      })
    else
      link_to(link_text, new_order_accounting_post_path(@order))
    end
  end
end
