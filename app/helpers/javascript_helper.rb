module JavascriptHelper
  def modal_create_link(path, element, title, options = {})
    options[:data] ||= {}
    options[:data][:update] ||= 'selectize'
    o = options.merge(
          id: "#{element}_create_link",
          data: { modal: '#modal',
                  title: title,
                  element: "##{element}",
                  remote: true,
                  type: :html })
    link_to(path, o) do
      icon(:plus) + " Erfassen".html_safe
    end
  end
end