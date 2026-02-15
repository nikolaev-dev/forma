require "test_helper"

class Api::GenerationsControllerTest < ActionDispatch::IntegrationTest
  test "status returns generation status as json" do
    generation = create(:generation, status: "running")

    get api_generation_status_path(generation.hashid)
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal "running", json["status"]
    assert_equal false, json["is_terminal"]
  end

  test "status returns terminal true for succeeded" do
    generation = create(:generation, status: "succeeded")

    get api_generation_status_path(generation.hashid)
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal "succeeded", json["status"]
    assert_equal true, json["is_terminal"]
  end

  test "status returns terminal true for failed" do
    generation = create(:generation, status: "failed")

    get api_generation_status_path(generation.hashid)
    json = JSON.parse(response.body)
    assert_equal true, json["is_terminal"]
  end

  test "status returns progress_step based on status" do
    gen_created = create(:generation, status: "created")
    gen_queued = create(:generation, status: "queued")
    gen_running = create(:generation, status: "running")

    get api_generation_status_path(gen_created.hashid)
    assert_equal 1, JSON.parse(response.body)["progress_step"]

    get api_generation_status_path(gen_queued.hashid)
    assert_equal 1, JSON.parse(response.body)["progress_step"]

    get api_generation_status_path(gen_running.hashid)
    assert_equal 2, JSON.parse(response.body)["progress_step"]
  end

  test "status returns 404 for nonexistent generation" do
    get api_generation_status_path("nonexistent")
    assert_response :not_found
  end
end
