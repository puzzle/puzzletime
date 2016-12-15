# encoding: UTF-8

module TooltipHelper
  def with_tooltip(tooltip_text, tag = :span)
    content_tag(tag, title: tooltip_text, data: { toggle: :tooltip }) do
      yield
    end
  end
end
