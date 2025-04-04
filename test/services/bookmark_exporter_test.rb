require "test_helper"

class BookmarkExporterTest < ActiveSupport::TestCase
  setup do
    @user = users(:first_user)
    @exporter = BookmarkExporter.new(@user)
    @bookmark = bookmarks(:public_bookmark)
  end

  teardown do
    # Clean up any bookmarks created during tests, but keep fixtures
    @user.bookmarks.where.not(id: [
      bookmarks(:public_bookmark).id,
      bookmarks(:private_bookmark).id
    ]).destroy_all
  end

  test "search returns matching bookmarks" do
    results = @exporter.search(@bookmark.title[0..3])

    assert_includes results.map { |r| r[:id] }, @bookmark.id
    result = results.find { |r| r[:id] == @bookmark.id }

    assert_equal @bookmark.title, result[:title]
    assert_equal @bookmark.url, result[:url]
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

    assert_equal [ @bookmark.title,
      @bookmark.description,
      @bookmark.created_at.iso8601,
      @bookmark.tags,
      Digest::MD5.hexdigest(@bookmark.url),
      @bookmark.is_private ? "no" : "yes", "no",
      "" ],
      [ result[:description],
        result[:extended],
        result[:time],
        result[:tags],
        result[:hash],
        result[:shared],
        result[:toread],
        result[:meta] ]
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
    assert_not_includes result_urls, older_bookmark.url
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

  test "preview with no start_id shows all bookmarks count" do
    test_user = User.create!(
      email_address: "test@example.com",
      username: "test_user",
      password_digest: "dummy"
    )
    exporter = BookmarkExporter.new(test_user)

    bookmark1 = test_user.bookmarks.create!(
      url: "https://example.com/1",
      title: "Bookmark 1",
      created_at: 1.day.ago
    )
    bookmark2 = test_user.bookmarks.create!(
      url: "https://example.com/2",
      title: "Bookmark 2",
      created_at: Time.current
    )

    results = exporter.preview

    assert_equal 2, results[:total]
    assert_equal 2, results[:bookmarks].length
  end

  test "preview with one bookmark shows just that bookmark" do
    test_user = User.create!(
      email_address: "test@example.com",
      username: "test_user",
      password_digest: "dummy"
    )
    exporter = BookmarkExporter.new(test_user)

    bookmark = test_user.bookmarks.create!(
      url: "https://example.com/single",
      title: "Single Bookmark",
      created_at: Time.current
    )

    results = exporter.preview(start_id: bookmark.id)

    assert_equal 1, results[:total]
    assert_equal 1, results[:bookmarks].length
    assert_equal bookmark.title, results[:bookmarks].first[:title]
  end

  # rubocop:disable Minitest/MultipleAssertions
  test "preview with many bookmarks shows newest and oldest" do
    test_user = User.create!(
      email_address: "test@example.com",
      username: "test_user",
      password_digest: "dummy"
    )
    exporter = BookmarkExporter.new(test_user)

    oldest = test_user.bookmarks.create!(
      url: "https://example.com/oldest",
      title: "Oldest Bookmark",
      created_at: 2.days.ago
    )
    middle = test_user.bookmarks.create!(
      url: "https://example.com/middle",
      title: "Middle Bookmark",
      created_at: 1.day.ago
    )
    newest = test_user.bookmarks.create!(
      url: "https://example.com/newest",
      title: "Newest Bookmark",
      created_at: Time.current
    )

    results = exporter.preview(start_id: oldest.id)

    assert_equal 3, results[:total]
    assert_equal 2, results[:bookmarks].length
    assert_equal newest.title, results[:bookmarks].first[:title]
    assert_equal oldest.title, results[:bookmarks].last[:title]
    assert_not_includes results[:bookmarks].map { |b| b[:title] }, middle.title
  end
  # rubocop:enable Minitest/MultipleAssertions

  test "preview includes formatted dates" do
    test_user = User.create!(
      email_address: "test@example.com",
      username: "test_user",
      password_digest: "dummy"
    )
    exporter = BookmarkExporter.new(test_user)

    bookmark = test_user.bookmarks.create!(
      url: "https://example.com/dated",
      title: "Dated Bookmark",
      created_at: Time.zone.parse("2024-03-15 12:00:00")
    )

    results = exporter.preview(start_id: bookmark.id)

    assert_equal "2024-03-15", results[:bookmarks].first[:date]
  end

  # rubocop:disable Minitest/MultipleAssertions
  test "preview with start_id shows correct count of exportable bookmarks" do
    test_user = User.create!(
      email_address: "test@example.com",
      username: "test_user",
      password_digest: "dummy"
    )
    exporter = BookmarkExporter.new(test_user)

    middle_date = Time.current
    older = test_user.bookmarks.create!(
      url: "https://example.com/older",
      title: "Older Bookmark",
      created_at: middle_date - 1.day
    )
    middle = test_user.bookmarks.create!(
      url: "https://example.com/middle",
      title: "Middle Bookmark",
      created_at: middle_date
    )
    newer = test_user.bookmarks.create!(
      url: "https://example.com/newer",
      title: "Newer Bookmark",
      created_at: middle_date + 1.day
    )

    results = exporter.preview(start_id: middle.id)

    assert_equal 2, results[:total]  # Should only count middle and newer bookmarks
    assert_includes results[:bookmarks].map { |b| b[:title] }, newer.title
    assert_includes results[:bookmarks].map { |b| b[:title] }, middle.title
    assert_not_includes results[:bookmarks].map { |b| b[:title] }, older.title
  end

  test "exports bookmarks in Netscape format" do
    test_user = User.create!(
      email_address: "test@example.com",
      username: "test_user",
      password_digest: "dummy"
    )
    exporter = BookmarkExporter.new(test_user)

    bookmark = test_user.bookmarks.create!(
      url: "http://example.com/test",
      title: "Test Bookmark",
      description: "Test Description",
      tags: "test,example",
      created_at: Time.zone.at(1577836800)  # 2020-01-01 00:00:00 UTC
    )

    html = exporter.export_netscape
    doc = Nokogiri::HTML(html)

    # Check DOCTYPE
    assert_includes html, "DOCTYPE NETSCAPE-Bookmark-file-1"

    # Find the bookmark link
    link = doc.at_css("a")

    assert_equal bookmark.url, link["href"]
    assert_equal bookmark.title, link.text
    assert_equal bookmark.description, link["description"]
    assert_equal bookmark.tags, link["tags"]
    assert_equal bookmark.created_at.to_i.to_s, link["add_date"]
  end
  # rubocop:enable Minitest/MultipleAssertions

  test "exports multiple bookmarks in Netscape format" do
    test_user = User.create!(
      email_address: "test@example.com",
      username: "test_user",
      password_digest: "dummy"
    )
    exporter = BookmarkExporter.new(test_user)

    test_user.bookmarks.create!(
      url: "http://example.com/1",
      title: "First Bookmark"
    )
    test_user.bookmarks.create!(
      url: "http://example.com/2",
      title: "Second Bookmark"
    )

    html = exporter.export_netscape
    doc = Nokogiri::HTML(html)

    links = doc.css("a")

    assert_equal 2, links.length
    assert_equal [ "First Bookmark", "Second Bookmark" ], links.map(&:text).sort
  end

  test "handles missing optional attributes in Netscape export" do
    test_user = User.create!(
      email_address: "test@example.com",
      username: "test_user",
      password_digest: "dummy"
    )
    exporter = BookmarkExporter.new(test_user)

    test_user.bookmarks.create!(
      url: "http://example.com/minimal",
      title: "Minimal Bookmark"
    )

    html = exporter.export_netscape
    doc = Nokogiri::HTML(html)

    link = doc.at_css("a")

    assert_empty link["description"]
    assert_empty link["tags"]
  end
end
