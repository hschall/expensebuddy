require "test_helper"

class EmpresasControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get empresas_index_url
    assert_response :success
  end

  test "should get edit" do
    get empresas_edit_url
    assert_response :success
  end

  test "should get update" do
    get empresas_update_url
    assert_response :success
  end
end
