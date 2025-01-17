require "test_helper"

class BookmarkExporterTest < ActiveSupport::TestCase
  setup do
    @user = users(:first_user)
    @exporter = BookmarkExporter.new(@user)
    @bookmark = bookmarks(:public_bookmark)
  end

  test "search returns matching bookmarks" do
    results = @exporter.search(@bookmark.title[0..3])

    assert_includes results.map { |r| r[:id] }, @bookmark.id
    result = results.find { |r| r[:id] == @bookmark.id }

    assert_equal @bookmark.title, result[:title]
    assert_equal @bookmark.url, result[:url]
    assert_equal @bookmark.created_at.strftime("%Y-%m-%d"), result[:date]
  end

  test "search limits results" do
    3.times do |i|
      @user.bookmarks.create!(
        url: "https://example.com/#{i}",
        title: "Test Bookmark #{i}"
      )
    end

    results = @exporter.search("", limit: 2)
    assert_equal 2, results.length
  end

  test "search matches both title and url" do
    results = @exporter.search(@bookmark.url[8..11])
    assert_includes results.map { |r| r[:id] }, @bookmark.id
  end

  test "export all bookmarks" do
    results = @exporter.export

    assert_includes results.map { |r| r[:href] }, @bookmark.url
    result = results.find { |r| r[:href] == @bookmark.url }

    assert_equal @bookmark.title, result[:description]
    assert_equal @bookmark.description, result[:extended]
    assert_equal @bookmark.created_at.iso8601, result[:time]
    assert_equal @bookmark.tags, result[:tags]
    assert_equal Digest::MD5.hexdigest(@bookmark.url), result[:hash]
    assert_equal @bookmark.is_private ? "no" : "yes", result[:shared]
    assert_equal "no", result[:toread]
    assert_equal "", result[:meta]
  end

  test "export from specific bookmark" do
    reference_time = @bookmark.created_at
    older_bookmark = @user.bookmarks.create!(
      url: "https://example.com/old",
      title: "Old bookmark",
      created_at: reference_time - 1.day
    )
    newer_bookmark = @user.bookmarks.create!(
      url: "https://example.com/new",
      title: "New bookmark",
      created_at: reference_time + 1.day
    )

    results = @exporter.export(start_id: @bookmark.id)
    result_urls = results.map { |r| r[:href] }

    assert_includes result_urls, @bookmark.url
    assert_includes result_urls, newer_bookmark.url
    refute_includes result_urls, older_bookmark.url
  end

  test "private bookmarks are marked as not shared" do
    private_bookmark = bookmarks(:private_bookmark)
    results = @exporter.export
    result = results.find { |r| r[:href] == private_bookmark.url }

    assert_equal "no", result[:shared]
  end

  test "public bookmarks are marked as shared" do
    public_bookmark = bookmarks(:public_bookmark)
    results = @exporter.export
    result = results.find { |r| r[:href] == public_bookmark.url }

    assert_equal "yes", result[:shared]
  end
end
