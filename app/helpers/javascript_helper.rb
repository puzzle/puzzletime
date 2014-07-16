module JavascriptHelper
  def new_modal_link(path, title)
    link_to(path,
            data: { modal: '#modal',
                    title: title,
                    remote: true,
                    type: 'html' }) do
      icon(:plus) + " Erfassen".html_safe
    end
  end
end