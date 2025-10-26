require "test_helper"

class Categories2ControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get categories2_index_url
    assert_response :success
  end
end
