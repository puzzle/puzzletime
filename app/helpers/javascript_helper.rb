module JavascriptHelper
  def modal_create_link(path, element, title, options = {})
    options[:id] ||= "#{element}_create_link"
    options[:data] ||= {}
    options[:data].merge!(modal: '#modal',
                          title: title,
                          element: "##{element}",
                          remote: true,
                          type: :html,
                          update: 'selectize')
    link_to(path, options) { safe_join([picon(:add), ' Erfassen']) }
  end
end
