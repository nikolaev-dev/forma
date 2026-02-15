require "test_helper"

class DesignsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @style = create(:style, :published)
    @design = create(:design, visibility: "public", style: @style, title: "Тестовый дизайн", slug: "test-design")
    @generation = create(:generation, design: @design, status: "succeeded")
    @variant = create(:generation_variant, :main, :succeeded, generation: @generation)
  end

  # S7: show (public design page)
  test "show renders public design page by slug" do
    get design_path(@design.slug)
    assert_response :success
    assert_match "Тестовый дизайн", response.body
  end

  test "show renders by hashid" do
    get design_path(@design.hashid)
    assert_response :success
  end

  test "show 404 for private design" do
    private_design = create(:design, visibility: "private")
    get design_path(private_design.hashid)
    assert_response :not_found
  end

  test "show renders OG meta tags" do
    get design_path(@design.slug)
    assert_response :success
    assert_select "meta[property='og:title']"
    assert_select "meta[property='og:description']"
  end

  test "show displays remixes block" do
    remix = create(:design, source_design: @design, visibility: "public", title: "Ремикс")
    create(:generation, design: remix, status: "succeeded")
    get design_path(@design.slug)
    assert_response :success
  end

  # Remix action
  test "remix creates fork and redirects to creation" do
    user = create(:user)
    sign_in_as(user)
    GenerationJob.stubs(:perform_later)
    Generations::RateLimiter.stubs(:check).returns({ allowed: true })
    Generations::RateLimiter.stubs(:check_ip).returns({ allowed: true })
    Generations::RateLimiter.stubs(:record!)

    post remix_design_path(@design.slug), params: {
      user_prompt: "Мой ремикс этого дизайна"
    }

    assert_response :redirect
    new_design = Design.last
    assert_equal @design.id, new_design.source_design_id
    assert_equal user.id, new_design.user_id
  end

  test "remix works for anonymous user" do
    GenerationJob.stubs(:perform_later)
    Generations::RateLimiter.stubs(:check).returns({ allowed: true })
    Generations::RateLimiter.stubs(:check_ip).returns({ allowed: true })
    Generations::RateLimiter.stubs(:record!)

    post remix_design_path(@design.slug), params: {
      user_prompt: "Анонимный ремикс"
    }

    assert_response :redirect
    new_design = Design.last
    assert_equal @design.id, new_design.source_design_id
  end

  test "remix redirects to limit_reached when limit exceeded" do
    user = create(:user)
    sign_in_as(user)
    AppSetting.set("user_daily_limit", { "value" => 0 })

    post remix_design_path(@design.slug), params: {
      user_prompt: "Ремикс"
    }

    assert_redirected_to limit_reached_generation_passes_path
  end
end
