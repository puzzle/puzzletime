module IntegrationHelper

  private

  def login_as(user, ref_path = nil)
    employee = user.is_a?(Employee) ? user : employees(user)
    employee.set_passwd('foobar')
    visit login_path(ref: ref_path)
    fill_in 'user', with: employee.shortname
    fill_in 'pwd', with: 'foobar'
    click_button 'Login'
  end

  # catch some errors occuring now and then in capybara tests
  def timeout_safe
    yield
  rescue Errno::ECONNREFUSED,
    Timeout::Error,
    Capybara::FrozenInTime,
    Capybara::ElementNotFound,
    Selenium::WebDriver::Error::StaleElementReferenceError => e
    skip e.message || e.class.name
  end

  def selectize(id, value)
    element = find("##{id} + .selectize-control")
    element.find('.selectize-input').click # open dropdown
    element.find('.selectize-dropdown-content').find('div', text: value).click
  end

  def drag(from_node, to_node)
    mouse_driver = page.driver.browser.mouse
    mouse_driver.down(from_node.native)
    mouse_driver.move_to(to_node.native)
    mouse_driver.up
  end

  def keyup(key)
    script = "var e = $.Event('keyup', { key: '#{key}' }); $(document).trigger(e);"
    page.driver.browser.execute_script(script)
  end

  Capybara.add_selector(:name) do
    xpath { |name| XPath.descendant[XPath.attr(:name).contains(name)] }
  end

end
