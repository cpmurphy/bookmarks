require "test_helper"

class BookmarkTest < ActiveSupport::TestCase
  test "search finds matches in title" do
    result = Bookmark.search("Example")
    assert_includes result, bookmarks(:one)
    assert_not_includes result, bookmarks(:private_bookmark)
  end

  test "search finds matches in description" do
    result = Bookmark.search("public")
    assert_includes result, bookmarks(:one)
    assert_not_includes result, bookmarks(:private_bookmark)
  end

  test "search finds matches in tags" do
    result = Bookmark.search("tag1")
    assert_includes result, bookmarks(:one)
    assert_not_includes result, bookmarks(:private_bookmark)
  end

  test "search is case insensitive" do
    result = Bookmark.search("EXAMPLE")
    assert_includes result, bookmarks(:one)
  end

  test "search returns empty when no matches" do
    result = Bookmark.search("nonexistent")
    assert_empty result
  end
end
