require "test_helper"

class ClassTypesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get class_types_index_url
    assert_response :success
  end
end
