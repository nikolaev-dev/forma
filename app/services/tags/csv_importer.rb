require "csv"

module Tags
  class CsvImporter
    # CSV format: name,slug,category_slug,visibility,kind,weight
    #
    # Usage:
    #   Tags::CsvImporter.call("path/to/tags.csv")
    #   Tags::CsvImporter.call("path/to/tags.csv", skip_existing: true)

    def self.call(file_path, skip_existing: true)
      new(file_path, skip_existing:).call
    end

    def initialize(file_path, skip_existing: true)
      @file_path = file_path
      @skip_existing = skip_existing
      @stats = { created: 0, skipped: 0, errors: [] }
    end

    def call
      CSV.foreach(@file_path, headers: true, liberal_parsing: true) do |row|
        import_row(row)
      end
      @stats
    end

    private

    def import_row(row)
      slug = row["slug"]&.strip
      return record_error(row, "missing slug") if slug.blank?

      if @skip_existing && Tag.exists?(slug: slug)
        @stats[:skipped] += 1
        return
      end

      category = TagCategory.find_by(slug: row["category_slug"]&.strip)
      return record_error(row, "category not found: #{row['category_slug']}") unless category

      tag = Tag.find_or_initialize_by(slug: slug)
      tag.assign_attributes(
        name: row["name"]&.strip,
        tag_category: category,
        visibility: row["visibility"]&.strip || "public",
        kind: row["kind"]&.strip || "generic",
        weight: row["weight"]&.strip&.to_f || 1.0
      )

      if tag.save
        @stats[:created] += 1
      else
        record_error(row, tag.errors.full_messages.join(", "))
      end
    end

    def record_error(row, message)
      @stats[:errors] << { row: row.to_h, message: message }
    end
  end
end
