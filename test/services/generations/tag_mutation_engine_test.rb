require "test_helper"

class Generations::TagMutationEngineTest < ActiveSupport::TestCase
  setup do
    @category = create(:tag_category)
    @tag_a = create(:tag, tag_category: @category, name: "Золото")
    @tag_b = create(:tag, tag_category: @category, name: "Серебро")
    @tag_c = create(:tag, tag_category: @category, name: "Бронза")
  end

  test "returns exactly 2 mutations" do
    mutations = Generations::TagMutationEngine.call(base_tags: [ @tag_a ])
    assert_equal 2, mutations.size
  end

  test "each mutation has required keys" do
    mutations = Generations::TagMutationEngine.call(base_tags: [ @tag_a ])
    mutations.each do |m|
      assert m.key?(:tags_added)
      assert m.key?(:tags_removed)
      assert m.key?(:summary)
    end
  end

  test "does not add base tags to mutations" do
    mutations = Generations::TagMutationEngine.call(base_tags: [ @tag_a, @tag_b ])
    mutations.each do |m|
      added_ids = m[:tags_added].map(&:id)
      assert_not_includes added_ids, @tag_a.id
      assert_not_includes added_ids, @tag_b.id
    end
  end

  test "does not add banned tags" do
    banned = create(:tag, :banned, tag_category: @category)
    mutations = Generations::TagMutationEngine.call(base_tags: [ @tag_a ])
    mutations.each do |m|
      assert_not_includes m[:tags_added].map(&:id), banned.id
    end
  end

  test "does not add conflicting tags" do
    conflicting = create(:tag, tag_category: @category, name: "Conflict")
    create(:tag_relation, from_tag: @tag_a, to_tag: conflicting, relation_type: "conflicts_with")

    mutations = Generations::TagMutationEngine.call(base_tags: [ @tag_a ])
    mutations.each do |m|
      assert_not_includes m[:tags_added].map(&:id), conflicting.id
    end
  end

  test "returns empty mutations when no candidates" do
    lonely_cat = create(:tag_category)
    lonely_tag = create(:tag, tag_category: lonely_cat)

    mutations = Generations::TagMutationEngine.call(base_tags: [ lonely_tag ])
    mutations.each do |m|
      assert_empty m[:tags_added]
      assert_empty m[:tags_removed]
    end
  end

  test "generates summary text" do
    mutations = Generations::TagMutationEngine.call(base_tags: [ @tag_a ])
    mutations.each do |m|
      if m[:tags_added].any?
        assert_includes m[:summary], "Добавили:"
      end
    end
  end
end
