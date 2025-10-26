require "test_helper"

class EmpresaDescriptionsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get empresa_descriptions_index_url
    assert_response :success
  end

  test "should get update_all" do
    get empresa_descriptions_update_all_url
    assert_response :success
  end
end
