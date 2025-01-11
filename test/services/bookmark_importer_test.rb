require "test_helper"

class BookmarkImporterTest < ActiveSupport::TestCase
  test "imports new bookmarks" do
    file = file_fixture("bookmarks.json")

    assert_difference "Bookmark.count" do
      results = BookmarkImporter.new(file).import
      assert_equal 1, results.imported
      assert_equal 0, results.skipped
    end
  end

  test "skips existing bookmarks" do
    file = file_fixture("bookmarks.json")
    # Create a bookmark that matches one in the import file
    Bookmark.create!(url: "http://another.example.com")

    assert_no_difference "Bookmark.count" do
      results = BookmarkImporter.new(file).import
      assert_equal 0, results.imported
      assert_equal 1, results.skipped
    end
  end

  test "handles invalid JSON" do
    file = file_fixture("invalid.json")

    assert_raises(JSON::ParserError) do
      BookmarkImporter.new(file).import
    end
  end
end
