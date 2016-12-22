# encoding: UTF-8

module TooltipHelper
  def with_tooltip(tooltip_text, options = {})
    tag = options.delete(:tag) || :span
    options = options.merge(title: tooltip_text, data: { toggle: :tooltip })
    content_tag(tag, options) do
      yield
    end
  end
end
