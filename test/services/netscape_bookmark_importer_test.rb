require "test_helper"

class NetscapeBookmarkImporterTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email_address: "test@example.com",
      username: "test_user",
      password_digest: "dummy"
    )
  end

  test "imports bookmarks from Netscape format" do
    file = file_fixture("netscape_bookmarks.html")
    importer = NetscapeBookmarkImporter.new(file.open, @user)

    results = importer.import
    assert_equal 2, results.imported
    assert_equal 0, results.skipped

    bookmark = @user.bookmarks.find_by(url: "http://example.com/bookmark1")
    assert_equal "Example Bookmark 1", bookmark.title
    assert_equal "First test bookmark", bookmark.description
    assert_equal "test,example", bookmark.tags
  end

  test "skips duplicate bookmarks" do
    # Create an existing bookmark
    @user.bookmarks.create!(
      url: "http://example.com/bookmark1",
      title: "Existing Bookmark"
    )

    file = file_fixture("netscape_bookmarks.html")
    importer = NetscapeBookmarkImporter.new(file.open, @user)

    results = importer.import
    assert_equal 1, results.imported
    assert_equal 1, results.skipped
  end

  test "handles missing optional attributes" do
    file = file_fixture("netscape_bookmarks_minimal.html")
    importer = NetscapeBookmarkImporter.new(file.open, @user)

    results = importer.import
    assert_equal 1, results.imported

    bookmark = @user.bookmarks.last
    assert_equal "[no title]", bookmark.title if bookmark.title.blank?
    assert_equal "", bookmark.description
    assert_equal "", bookmark.tags
  end
end
