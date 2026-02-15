require "test_helper"

class TagRelationTest < ActiveSupport::TestCase
  test "valid with factory defaults" do
    assert create(:tag_relation).persisted?
  end

  test "invalid without relation_type" do
    assert_not build(:tag_relation, relation_type: nil).valid?
  end

  test "no self-relations allowed" do
    tag = create(:tag)
    assert_not build(:tag_relation, from_tag: tag, to_tag: tag).valid?
  end

  test "unique constraint on from_tag + to_tag + relation_type" do
    tag_a = create(:tag)
    tag_b = create(:tag)
    create(:tag_relation, from_tag: tag_a, to_tag: tag_b, relation_type: "related")
    assert_not build(:tag_relation, from_tag: tag_a, to_tag: tag_b, relation_type: "related").valid?
  end

  test "same pair with different relation_type is valid" do
    tag_a = create(:tag)
    tag_b = create(:tag)
    create(:tag_relation, from_tag: tag_a, to_tag: tag_b, relation_type: "related")
    assert build(:tag_relation, from_tag: tag_a, to_tag: tag_b, relation_type: "conflicts_with").valid?
  end

  test "relation_type enum uses string values" do
    rel = create(:tag_relation, relation_type: "conflicts_with")
    raw = TagRelation.connection.select_value("SELECT relation_type FROM tag_relations WHERE id = #{rel.id}")
    assert_equal "conflicts_with", raw
  end
end
