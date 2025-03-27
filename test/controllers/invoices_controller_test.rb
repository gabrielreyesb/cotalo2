require "test_helper"

class InvoicesControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get invoices_create_url
    assert_response :success
  end

  test "should get show" do
    get invoices_show_url
    assert_response :success
  end

  test "should get status" do
    get invoices_status_url
    assert_response :success
  end
end
