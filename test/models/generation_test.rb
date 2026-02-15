require "test_helper"

class GenerationTest < ActiveSupport::TestCase
  test "valid with factory defaults" do
    assert build(:generation).valid?
  end

  test "invalid without provider" do
    assert_not build(:generation, provider: nil).valid?
  end

  test "status enum uses string values" do
    gen = create(:generation, status: "queued")
    raw = Generation.connection.select_value("SELECT status FROM generations WHERE id = #{gen.id}")
    assert_equal "queued", raw
  end

  test "source enum uses string values" do
    gen = create(:generation, source: "refine")
    raw = Generation.connection.select_value("SELECT source FROM generations WHERE id = #{gen.id}")
    assert_equal "refine", raw
  end

  test "generates hashid" do
    gen = create(:generation)
    assert gen.hashid.present?
  end

  test "queue! transitions status" do
    gen = create(:generation, status: "created")
    gen.queue!
    assert_equal "queued", gen.status
  end

  test "start! transitions status and sets started_at" do
    gen = create(:generation, status: "queued")
    gen.start!
    assert_equal "running", gen.status
    assert_not_nil gen.started_at
  end

  test "finish! sets succeeded when all variants succeed" do
    gen = create(:generation, status: "running")
    create(:generation_variant, :main, :succeeded, generation: gen)
    create(:generation_variant, :mutation_a, :succeeded, generation: gen)
    create(:generation_variant, :mutation_b, :succeeded, generation: gen)

    gen.finish!
    assert_equal "succeeded", gen.status
    assert_not_nil gen.finished_at
  end

  test "finish! sets partial when some variants succeed" do
    gen = create(:generation, status: "running")
    create(:generation_variant, :main, :succeeded, generation: gen)
    create(:generation_variant, :mutation_a, :succeeded, generation: gen)
    create(:generation_variant, :mutation_b, :failed, generation: gen)

    gen.finish!
    assert_equal "partial", gen.status
  end

  test "finish! sets failed when all variants fail" do
    gen = create(:generation, status: "running")
    create(:generation_variant, :main, :failed, generation: gen)
    create(:generation_variant, :mutation_a, :failed, generation: gen)
    create(:generation_variant, :mutation_b, :failed, generation: gen)

    gen.finish!
    assert_equal "failed", gen.status
  end

  test "cancel! transitions status" do
    gen = create(:generation, status: "running")
    gen.cancel!
    assert_equal "canceled", gen.status
    assert_not_nil gen.finished_at
  end
end
