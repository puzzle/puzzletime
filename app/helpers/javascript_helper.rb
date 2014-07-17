module JavascriptHelper
  def modal_create_link(path, element, title, options = {})
    options[:update] ||= 'selectize'
    link_to(path,
            id: "#{element}_create_link",
            data: options.merge(
                    modal: '#modal',
                    title: title,
                    element: "##{element}",
                    remote: true,
                    type: :html )) do
      icon(:plus) + " Erfassen".html_safe
    end
  end
end