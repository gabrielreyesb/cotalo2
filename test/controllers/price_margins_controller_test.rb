require "test_helper"

class PriceMarginsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get price_margins_index_url
    assert_response :success
  end

  test "should get new" do
    get price_margins_new_url
    assert_response :success
  end

  test "should get create" do
    get price_margins_create_url
    assert_response :success
  end

  test "should get edit" do
    get price_margins_edit_url
    assert_response :success
  end

  test "should get update" do
    get price_margins_update_url
    assert_response :success
  end

  test "should get destroy" do
    get price_margins_destroy_url
    assert_response :success
  end
end
