require "test_helper"

class NotebookSkuTest < ActiveSupport::TestCase
  test "valid with factory defaults" do
    assert build(:notebook_sku).valid?
  end

  test "invalid without code" do
    assert_not build(:notebook_sku, code: nil).valid?
  end

  test "invalid without name" do
    assert_not build(:notebook_sku, name: nil).valid?
  end

  test "invalid without price_cents" do
    assert_not build(:notebook_sku, price_cents: nil).valid?
  end

  test "code must be unique" do
    create(:notebook_sku, code: "base")
    assert_not build(:notebook_sku, code: "base").valid?
  end

  test "price_cents must be positive" do
    assert_not build(:notebook_sku, price_cents: 0).valid?
    assert_not build(:notebook_sku, price_cents: -100).valid?
  end

  test "scope active returns only active skus" do
    active = create(:notebook_sku, is_active: true)
    create(:notebook_sku, is_active: false)

    assert_includes NotebookSku.active, active
    assert_equal 1, NotebookSku.active.count
  end
end
