# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module JavascriptHelper
  def modal_create_link(path, element, title, options = {})
    options[:id] ||= "#{element}_create_link"
    options[:data] ||= {}
    options[:data].merge!(modal: '#modal',
                          title:,
                          element: "##{element}",
                          remote: true,
                          type: :html,
                          update: 'selectize')
    link_to(path, options) { safe_join([picon(:add), ' Erfassen']) }
  end
end
