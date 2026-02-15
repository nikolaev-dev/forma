require "test_helper"

class CollectionTest < ActiveSupport::TestCase
  test "valid with factory defaults" do
    assert build(:collection).valid?
  end

  test "invalid without name" do
    assert_not build(:collection, name: nil).valid?
  end

  test "invalid without slug" do
    assert_not build(:collection, slug: nil).valid?
  end

  test "slug must be unique" do
    create(:collection, slug: "test-slug")
    assert_not build(:collection, slug: "test-slug").valid?
  end

  test "collection_type enum uses string values" do
    collection = create(:collection, collection_type: "limited", edition_size: 10, stock_remaining: 10)
    raw = Collection.connection.select_value("SELECT collection_type FROM collections WHERE id = #{collection.id}")
    assert_equal "limited", raw
  end

  test "regular collection does not require edition_size" do
    assert build(:collection, collection_type: "regular", edition_size: nil).valid?
  end

  test "limited collection requires edition_size" do
    assert_not build(:collection, collection_type: "limited", edition_size: nil).valid?
  end

  test "limited collection with valid edition_size is valid" do
    assert build(:collection, :limited).valid?
  end

  test "edition_size must be positive for limited" do
    assert_not build(:collection, collection_type: "limited", edition_size: 0).valid?
    assert_not build(:collection, collection_type: "limited", edition_size: -1).valid?
  end

  test "stock_remaining cannot be negative" do
    assert_not build(:collection, :limited, stock_remaining: -1).valid?
  end

  test "active scope returns only active" do
    create(:collection, is_active: true)
    create(:collection, :inactive)
    assert_equal 1, Collection.active.count
  end

  test "ordered scope sorts by position" do
    c2 = create(:collection, position: 2)
    c1 = create(:collection, position: 1)
    c3 = create(:collection, position: 3)
    assert_equal [ c1, c2, c3 ], Collection.ordered.to_a
  end

  test "has_many designs" do
    collection = create(:collection)
    design = create(:design, collection: collection)
    assert_includes collection.designs, design
  end

  test "nullifies designs on destroy" do
    collection = create(:collection)
    design = create(:design, collection: collection)
    collection.destroy!
    assert_nil design.reload.collection_id
  end

  test "decrement_stock! decreases stock_remaining" do
    collection = create(:collection, :limited, stock_remaining: 5)
    collection.decrement_stock!
    assert_equal 4, collection.reload.stock_remaining
  end

  test "decrement_stock! raises when out of stock" do
    collection = create(:collection, :limited, stock_remaining: 0)
    assert_raises(RuntimeError, "Out of stock") { collection.decrement_stock! }
  end

  test "decrement_stock! raises for regular collection" do
    collection = create(:collection, collection_type: "regular")
    assert_raises(RuntimeError) { collection.decrement_stock! }
  end
end
