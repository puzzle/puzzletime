module MultiWorktimesHelper

  def toggleable_field(attr, span = 2, &block)
    content_tag(:div, class: 'form-group') do
      content_tag(:div, class: 'col-md-2') do
        content_tag(:label, class: 'control-label') do
          check_box_tag("change_#{attr}",
                        true,
                        params["change_#{attr}"],
                        data: { enable: ".#{attr}" }) +
          ' &nbsp '.html_safe +
          Ordertime.human_attribute_name(attr)
        end
      end +
      content_tag(:div, class: "col-md-#{span}", &block)
    end
  end

end
