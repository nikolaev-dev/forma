require "test_helper"

class DesignTagTest < ActiveSupport::TestCase
  test "valid with factory defaults" do
    assert build(:design_tag).valid?
  end

  test "invalid without source" do
    assert_not build(:design_tag, source: nil).valid?
  end

  test "tag_id must be unique per design" do
    design = create(:design)
    tag = create(:tag)
    create(:design_tag, design: design, tag: tag)
    assert_not build(:design_tag, design: design, tag: tag).valid?
  end

  test "same tag on different designs is valid" do
    tag = create(:tag)
    create(:design_tag, tag: tag)
    assert build(:design_tag, tag: tag).valid?
  end

  test "source enum uses string values" do
    dt = create(:design_tag, source: "system")
    raw = DesignTag.connection.select_value("SELECT source FROM design_tags WHERE id = #{dt.id}")
    assert_equal "system", raw
  end

  test "all source values are valid" do
    %w[user system admin autotag].each do |src|
      assert build(:design_tag, source: src).valid?, "#{src} should be valid"
    end
  end
end
