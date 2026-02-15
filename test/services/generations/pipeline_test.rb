require "test_helper"

class Generations::PipelineTest < ActiveSupport::TestCase
  setup do
    # Stub GenerationJob and RateLimiter to avoid Redis connection
    GenerationJob.stubs(:perform_later).returns(true)
    Generations::RateLimiter.stubs(:check).returns({ allowed: true })
    Generations::RateLimiter.stubs(:check_ip).returns({ allowed: true })
    Generations::RateLimiter.stubs(:record!)

    @user = create(:user)
    @style = create(:style, generation_preset: { "style_prompt" => "test prompt" })
    @category = create(:tag_category)
    @tags = create_list(:tag, 3, tag_category: @category)
  end

  test "creates design, prompt, generation, and 3 variants" do
    gen = Generations::Pipeline.call(
      user_prompt: "красивый блокнот",
      style: @style,
      tags: @tags,
      user: @user
    )

    assert gen.persisted?
    assert_equal "created", gen.status
    assert_equal "test", gen.provider
    assert_equal @user, gen.user

    # Design
    design = gen.design
    assert design.persisted?
    assert_equal @user, design.user
    assert_equal @style, design.style
    assert_includes design.title, "красивый блокнот"

    # Prompt
    assert design.prompt.present?
    assert_equal "красивый блокнот", design.prompt.current_text

    # 3 Variants
    assert_equal 3, gen.generation_variants.count
    kinds = gen.generation_variants.pluck(:kind).sort
    assert_equal %w[main mutation_a mutation_b], kinds

    # Main variant has composed prompt with style
    main = gen.generation_variants.find_by(kind: "main")
    assert_includes main.composed_prompt, "test prompt"
    assert_includes main.composed_prompt, "no logos"
  end

  test "reuses existing design when passed" do
    design = create(:design, user: @user)

    gen = Generations::Pipeline.call(
      user_prompt: "обновлённый промпт",
      user: @user,
      design: design
    )

    assert_equal design, gen.design
    assert_equal 1, Design.where(user: @user).count
  end

  test "enqueues GenerationJob" do
    GenerationJob.expects(:perform_later).once

    Generations::Pipeline.call(
      user_prompt: "блокнот",
      user: @user
    )
  end

  test "stores tags_snapshot" do
    gen = Generations::Pipeline.call(
      user_prompt: "блокнот",
      tags: @tags,
      user: @user
    )

    assert_equal @tags.map(&:slug).sort, gen.tags_snapshot["tags"].sort
  end

  test "raises LimitExceeded when daily limit reached" do
    AppSetting.set("user_daily_limit", { "value" => 2 })
    create(:usage_counter, user: @user, generations_count: 2)

    assert_raises(Generations::Pipeline::LimitExceeded) do
      Generations::Pipeline.call(
        user_prompt: "блокнот",
        user: @user
      )
    end
  end

  test "increments usage counter on successful generation" do
    gen = Generations::Pipeline.call(
      user_prompt: "блокнот",
      user: @user
    )

    counter = UsageCounter.find_by(user: @user, period: Date.current)
    assert_equal 1, counter.generations_count
  end
end
