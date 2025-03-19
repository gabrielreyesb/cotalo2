require "test_helper"

class ExtrasControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get extras_index_url
    assert_response :success
  end

  test "should get show" do
    get extras_show_url
    assert_response :success
  end

  test "should get new" do
    get extras_new_url
    assert_response :success
  end

  test "should get edit" do
    get extras_edit_url
    assert_response :success
  end

  test "should get create" do
    get extras_create_url
    assert_response :success
  end

  test "should get update" do
    get extras_update_url
    assert_response :success
  end

  test "should get destroy" do
    get extras_destroy_url
    assert_response :success
  end
end
