require "test_helper"

class BookmarkImporterTest < ActiveSupport::TestCase
  setup do
    @user = users(:first_user)
  end

  test "imports new bookmarks" do
    file = file_fixture("bookmarks.json")

    assert_difference "Bookmark.count" do
      results = BookmarkImporter.new(file, @user).import
      assert_equal 1, results.imported
      assert_equal 0, results.skipped
    end
  end

  test "skips existing bookmarks" do
    file = file_fixture("bookmarks.json")
    # Create a bookmark that matches one in the import file
    Bookmark.create!(user: @user, url: "http://another.example.com", title: "Another Example")

    assert_no_difference "Bookmark.count" do
      results = BookmarkImporter.new(file, @user).import
      assert_equal 0, results.imported
      assert_equal 1, results.skipped
    end
  end

  test "handles invalid JSON" do
    file = file_fixture("invalid.json")

    assert_raises(JSON::ParserError) do
      BookmarkImporter.new(file, @user).import
    end
  end
end
