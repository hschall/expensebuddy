require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get turbo_test" do
    get pages_turbo_test_url
    assert_response :success
  end
end
