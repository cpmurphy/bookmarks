require "test_helper"

class BookmarkImporterTest < ActiveSupport::TestCase
  setup do
    @user = users(:first_user)
  end

  test "imports new bookmarks" do
    file = file_fixture("bookmarks.json")

    results = BookmarkImporter.new(file, @user).import

    assert_equal 1, results.imported
    assert_equal 0, results.skipped
  end

  test "imports data from new bookmarks" do
    file = file_fixture("bookmarks.json")

    results = BookmarkImporter.new(file, @user).import
    bookmark = @user.bookmarks.find_by(url: "http://another.example.com")

    assert_equal [ "Another Example Site", "Another test bookmark", "test,example", Time.zone.parse("2024-01-01T12:00:00Z") ],
      [ bookmark.title, bookmark.description, bookmark.tags, bookmark.created_at ]
  end

  test "imports bookmarks with missing time" do
    json = [
      {
        "href" => "http://example.com/notime",
        "description" => "No Time Bookmark",
        "extended" => "A description",
        "tags" => "test"
      }
    ].to_json

    file = StringIO.new(json)

    freeze_time do
      results = BookmarkImporter.new(file, @user).import

      assert_equal 1, results.imported
      assert_equal 0, results.skipped

      bookmark = @user.bookmarks.find_by(url: "http://example.com/notime")

      assert_equal Time.current, bookmark.created_at
    end
  end

  test "skips duplicate URLs" do
    existing = @user.bookmarks.create!(
      url: "http://example.com/dupe",
      title: "Existing Bookmark",
      description: "Already here"
    )

    json = [
      {
        "href" => "http://example.com/dupe",
        "description" => "Duplicate URL",
        "extended" => "Won't be imported",
        "tags" => "test"
      }
    ].to_json

    file = StringIO.new(json)
    results = BookmarkImporter.new(file, @user).import

    assert_equal 0, results.imported
    assert_equal 1, results.skipped
  end

  test "does't modify originals when skipping duplicate URLs" do
    existing = @user.bookmarks.create!(
      url: "http://example.com/dupe",
      title: "Existing Bookmark",
      description: "Already here"
    )

    json = [
      {
        "href" => "http://example.com/dupe",
        "description" => "Duplicate URL",
        "extended" => "Won't be imported",
        "tags" => "test"
      }
    ].to_json

    file = StringIO.new(json)
    results = BookmarkImporter.new(file, @user).import
    existing.reload

    assert_equal "Existing Bookmark", existing.title
    assert_equal "Already here", existing.description
  end
end
