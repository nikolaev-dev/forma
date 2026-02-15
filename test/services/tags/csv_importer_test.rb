require "test_helper"
require "tempfile"

class Tags::CsvImporterTest < ActiveSupport::TestCase
  setup do
    @category = create(:tag_category, slug: "mood")
    @csv_file = Tempfile.new(["tags", ".csv"])
  end

  teardown do
    @csv_file.close
    @csv_file.unlink
  end

  test "imports tags from CSV" do
    write_csv("name,slug,category_slug,visibility,kind,weight\nСпокойствие,calm,mood,public,generic,1.0")

    stats = Tags::CsvImporter.call(@csv_file.path)

    assert_equal 1, stats[:created]
    assert_equal 0, stats[:skipped]
    assert stats[:errors].empty?

    tag = Tag.find_by(slug: "calm")
    assert_equal "Спокойствие", tag.name
    assert_equal @category, tag.tag_category
    assert_equal "public", tag.visibility
  end

  test "skips existing tags when skip_existing is true" do
    create(:tag, slug: "calm", tag_category: @category)
    write_csv("name,slug,category_slug,visibility,kind,weight\nСпокойствие,calm,mood,public,generic,1.0")

    stats = Tags::CsvImporter.call(@csv_file.path, skip_existing: true)

    assert_equal 0, stats[:created]
    assert_equal 1, stats[:skipped]
  end

  test "updates existing tags when skip_existing is false" do
    create(:tag, slug: "calm", name: "Old Name", tag_category: @category)
    write_csv("name,slug,category_slug,visibility,kind,weight\nNew Name,calm,mood,public,generic,1.0")

    stats = Tags::CsvImporter.call(@csv_file.path, skip_existing: false)

    assert_equal 1, stats[:created]
    assert_equal "New Name", Tag.find_by(slug: "calm").name
  end

  test "records error for missing slug" do
    write_csv("name,slug,category_slug,visibility,kind,weight\nNoSlug,,mood,public,generic,1.0")

    stats = Tags::CsvImporter.call(@csv_file.path)

    assert_equal 0, stats[:created]
    assert_equal 1, stats[:errors].size
    assert_match(/missing slug/, stats[:errors].first[:message])
  end

  test "records error for unknown category" do
    write_csv("name,slug,category_slug,visibility,kind,weight\nTag,mytag,nonexistent,public,generic,1.0")

    stats = Tags::CsvImporter.call(@csv_file.path)

    assert_equal 0, stats[:created]
    assert_equal 1, stats[:errors].size
    assert_match(/category not found/, stats[:errors].first[:message])
  end

  test "imports multiple rows" do
    write_csv(<<~CSV)
      name,slug,category_slug,visibility,kind,weight
      Тег1,tag1,mood,public,generic,1.0
      Тег2,tag2,mood,public,generic,0.5
      Тег3,tag3,mood,hidden,generic,2.0
    CSV

    stats = Tags::CsvImporter.call(@csv_file.path)

    assert_equal 3, stats[:created]
    assert_equal "hidden", Tag.find_by(slug: "tag3").visibility
  end

  private

  def write_csv(content)
    @csv_file.write(content)
    @csv_file.rewind
  end
end
