require "test_helper"

class ManufacturingProcessesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get manufacturing_processes_index_url
    assert_response :success
  end

  test "should get show" do
    get manufacturing_processes_show_url
    assert_response :success
  end

  test "should get new" do
    get manufacturing_processes_new_url
    assert_response :success
  end

  test "should get edit" do
    get manufacturing_processes_edit_url
    assert_response :success
  end

  test "should get create" do
    get manufacturing_processes_create_url
    assert_response :success
  end

  test "should get update" do
    get manufacturing_processes_update_url
    assert_response :success
  end

  test "should get destroy" do
    get manufacturing_processes_destroy_url
    assert_response :success
  end
end
