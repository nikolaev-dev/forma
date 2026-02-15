require "test_helper"

class TagSynonymTest < ActiveSupport::TestCase
  test "valid with factory defaults" do
    assert build(:tag_synonym).valid?
  end

  test "invalid without phrase" do
    assert_not build(:tag_synonym, phrase: nil).valid?
  end

  test "auto-sets normalized from phrase" do
    synonym = create(:tag_synonym, phrase: "  Hello  World  ")
    assert_equal "hello world", synonym.normalized
  end

  test "normalized must be unique" do
    create(:tag_synonym, phrase: "test")
    assert_not build(:tag_synonym, phrase: "test").valid?
  end
end
