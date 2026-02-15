require "test_helper"

class GenerationPassesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
  end

  # L1: limit_reached (available to all, no auth needed)
  test "limit_reached renders for guest" do
    get limit_reached_generation_passes_path
    assert_response :success
    assert_match "Лимит исчерпан", response.body
  end

  test "limit_reached renders for user" do
    sign_in_as(@user)
    get limit_reached_generation_passes_path
    assert_response :success
  end

  # new: purchase form (requires auth)
  test "new redirects to login if not authenticated" do
    get new_generation_pass_path
    assert_redirected_to root_path
  end

  test "new renders purchase form for authenticated user" do
    sign_in_as(@user)
    get new_generation_pass_path
    assert_response :success
    assert_match "Безлимит", response.body
  end

  test "new redirects if user already has active pass" do
    sign_in_as(@user)
    create(:generation_pass, user: @user, starts_at: 1.hour.ago, ends_at: 23.hours.from_now)
    get new_generation_pass_path
    assert_redirected_to new_creation_path
  end

  # create: initiate payment
  test "create redirects to login if not authenticated" do
    post generation_passes_path
    assert_redirected_to root_path
  end

  test "create creates generation_pass and payment, redirects to yookassa" do
    sign_in_as(@user)

    mock_result = {
      provider_payment_id: "pay_test_123",
      status: "pending",
      confirmation_url: "https://yookassa.ru/pay/test",
      idempotence_key: "test-key",
      raw: {}
    }

    Payments::YookassaClient.any_instance
      .stubs(:create_payment)
      .returns(mock_result)

    assert_difference [ "GenerationPass.count", "Payment.count" ], 1 do
      post generation_passes_path
    end

    pass = GenerationPass.last
    assert_equal @user.id, pass.user_id
    assert_equal "active", pass.status
    assert_equal 10000, pass.price_cents

    payment = Payment.last
    assert_equal "GenerationPass", payment.payable_type
    assert_equal pass.id, payment.payable_id
    assert_equal 10000, payment.amount_cents
    assert_equal "pay_test_123", payment.provider_payment_id

    assert_redirected_to "https://yookassa.ru/pay/test"
  end

  # confirmed: after payment success
  test "confirmed renders success page" do
    sign_in_as(@user)
    pass = create(:generation_pass, user: @user)
    get confirmed_generation_pass_path(pass)
    assert_response :success
    assert_match "Безлимит активирован", response.body
  end
end
