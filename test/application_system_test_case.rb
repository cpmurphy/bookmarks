require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Use a shorter timeout but not too short
  Capybara.default_max_wait_time = 10

  # Increase the server timeout
  Capybara.register_server :puma do |app, port, host|
    require "rack/handler/puma"
    Rack::Handler::Puma.run(app, Host: host, Port: port, Threads: "0:1", Silent: true)
  end

  driven_by :selenium, using: :headless_chrome do |options|
    # Chrome settings for running in Docker
    options.add_argument("--headless=new")
    options.add_argument("--no-sandbox")  # Required for Docker
    options.add_argument("--disable-dev-shm-usage")  # Required for Docker
    options.add_argument("--disable-gpu")
    options.add_argument("--window-size=1400,1400")

    # Additional Docker-specific settings
    options.add_argument("--remote-debugging-port=9222")
    options.add_argument("--disable-site-isolation-trials")
  end

  # Helper method for debugging
  def debug_page
    save_and_open_screenshot
    save_page
  end

  def sign_in_as(user)
    visit new_session_path
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "password"
    click_on "Sign in"

    assert_text "Sign out"
  end
end
