#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module IntegrationHelper
  private

  def login_as(user)
    employee = user.is_a?(Employee) ? user : employees(user)
    super(employee)
  end

  def set_period(start_date: '1.1.2006', end_date: '31.12.2006', back_url: current_url)
    visit periods_path(back_url: back_url)
    fill_in 'period_start_date', with: start_date, fill_options: { clear: :backspace }
    fill_in 'period_end_date', with: end_date, fill_options: { clear: :backspace }
    find('input[name=commit]').click
  end

  # catch some errors occuring now and then in capybara tests
  def timeout_safe
    yield
  rescue Errno::ECONNREFUSED,
         Timeout::Error,
         Capybara::FrozenInTime,
         Capybara::ElementNotFound => e
    if ENV['CI'] == true
      skip e.message || e.class.name
    else
      raise
    end
  end

  def open_selectize(id, options = {})
    element = find("##{id} + .selectize-control")
    element.find('.selectize-input').trigger('click') unless options[:no_click]
    element.find('.selectize-input input').native.send_keys(:backspace) if options[:clear]
    element.find('.selectize-input input').native.send_keys(options[:term].chars) if options[:term].present?
    if options[:assert_empty]
      page.assert_no_selector('.selectize-dropdown-content')
    else
      page.assert_selector('.selectize-dropdown-content')
      find('.selectize-dropdown-content')
    end
  end

  def selectize(id, value, options = {})
    open_selectize(id, options).find('.selectize-option,.option', text: value).trigger('click')
  end

  def mouse
    page.driver.browser.mouse
  end

  def move_mouse_to(element)
    x, y = element.native.node.find_position
    mouse.move(x:, y:)
  end

  def drag(from_node, *to_nodes)
    move_mouse_to(from_node)
    mouse.down

    to_nodes.each do |to_node|
      move_mouse_to(to_node)
    end
    mouse.up
  end

  Capybara.add_selector(:name) do
    xpath { |name| XPath.descendant[XPath.attr(:name).contains(name)] }
  end

  def clear_cookies
    Capybara.current_session.driver.clear_cookies
  end
end
