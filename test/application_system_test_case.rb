require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  if ENV["HEADLESS_CHROME"] == "1"
    driven_by :selenium, using: :headless_chrome, screen_size: [ 390, 844 ]
  else
    driven_by :rack_test
  end
end
