require "test_helper"

class RubricControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get rubric_url
    assert_response :success
  end
end
