require "test_helper"

class FillingTest < ActiveSupport::TestCase
  test "valid with factory defaults" do
    assert build(:filling).valid?
  end

  test "invalid without name" do
    assert_not build(:filling, name: nil).valid?
  end

  test "invalid without slug" do
    assert_not build(:filling, slug: nil).valid?
  end

  test "invalid without filling_type" do
    assert_not build(:filling, filling_type: nil).valid?
  end

  test "slug must be unique" do
    create(:filling, slug: "grid")
    assert_not build(:filling, slug: "grid").valid?
  end

  test "filling_type enum uses string values" do
    filling = create(:filling, filling_type: "dot")
    raw = Filling.connection.select_value("SELECT filling_type FROM fillings WHERE id = #{filling.id}")
    assert_equal "dot", raw
  end

  test "scope active returns only active fillings" do
    active = create(:filling, is_active: true)
    create(:filling, is_active: false)

    assert_includes Filling.active, active
    assert_equal 1, Filling.active.count
  end
end
