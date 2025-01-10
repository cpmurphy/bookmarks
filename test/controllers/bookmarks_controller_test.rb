require "test_helper"

class BookmarksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @bookmark = bookmarks(:one)
    @private_bookmark = bookmarks(:private)
    @user = users(:one)
  end

  test "should get index with public bookmarks when not signed in" do
    get bookmarks_url
    assert_response :success
    assert_includes @response.body, @bookmark.title
    assert_not_includes @response.body, @private_bookmark.title
  end

  test "should get index with all bookmarks when signed in" do
    sign_in_as(@user)
    get bookmarks_url
    assert_response :success
    assert_includes @response.body, @bookmark.title
    assert_includes @response.body, @private_bookmark.title
  end

  test "should show public bookmark when not signed in" do
    get bookmark_url(@bookmark)
    assert_response :success
  end

  test "should not show private bookmark when not signed in" do
    get bookmark_url(@private_bookmark)
    assert_redirected_to bookmarks_path
    assert_equal "You must be signed in to view private bookmarks", flash[:alert]
  end

  test "should show private bookmark when signed in" do
    sign_in_as(@user)
    get bookmark_url(@private_bookmark)
    assert_response :success
  end

  test "should get new when signed in" do
    sign_in_as(@user)
    get new_bookmark_url
    assert_response :success
  end

  test "should not get new when not signed in" do
    get new_bookmark_url
    assert_redirected_to new_session_path
  end

  test "should create bookmark when signed in" do
    sign_in_as(@user)
    assert_difference("Bookmark.count") do
      @bookmark.url = 'http://example.com/2'
      post bookmarks_url, params: { bookmark: { description: @bookmark.description, tags: @bookmark.tags, title: @bookmark.title, url: @bookmark.url } }
    end

    assert_redirected_to bookmark_url(Bookmark.last)
  end

  test "should show bookmark" do
    get bookmark_url(@bookmark)
    assert_response :success
  end

  test "should get edit" do
    sign_in_as(@user)
    get edit_bookmark_url(@bookmark)
    assert_response :success
  end

  test "should update bookmark" do
    sign_in_as(@user)
    @bookmark.url = 'http://example.com/3'
    patch bookmark_url(@bookmark), params: { bookmark: { description: @bookmark.description, tags: @bookmark.tags, title: @bookmark.title, url: @bookmark.url } }
    assert_redirected_to bookmark_url(@bookmark)
  end

  test "should destroy bookmark when signed in" do
    sign_in_as(@user)
    assert_difference("Bookmark.count", -1) do
      delete bookmark_url(@bookmark)
    end

    assert_redirected_to bookmarks_url
  end

  test "should import bookmarks from JSON file when signed in" do
    sign_in_as(@user)
    # Create a temp file with test JSON data
    file = Tempfile.new(['bookmarks', '.json'])
    file.write([{
      "href" => "https://example.com",
      "description" => "Example Site",
      "extended" => "A test bookmark",
      "tags" => "test,example",
      "time" => "2024-12-30T00:16:38Z"
    }].to_json)
    file.rewind

    assert_difference("Bookmark.count") do
      post import_bookmarks_path, params: { file: fixture_file_upload(file.path, 'application/json') }
    end

    assert_redirected_to bookmarks_path
    assert_match /Successfully imported 1 bookmark/, flash[:notice]

    # Verify the imported bookmark data
    bookmark = Bookmark.last
    assert_equal "https://example.com", bookmark.url
    assert_equal "Example Site", bookmark.title
    assert_equal "A test bookmark", bookmark.description
    assert_equal "test,example", bookmark.tags
    assert_equal Time.zone.parse("2024-12-30T00:16:38Z"), bookmark.created_at
  end

  test "should handle duplicate URLs during import when signed in" do
    # First create a bookmark
    Bookmark.create!(
      url: "https://example.com",
      title: "Existing Bookmark"
    )

    # Try to import the same URL
    file = Tempfile.new(['bookmarks', '.json'])
    file.write([{
      "href" => "https://example.com",
      "description" => "Duplicate Site",
      "time" => "2024-12-30T00:16:38Z"
    }].to_json)
    file.rewind

    sign_in_as(@user)
    assert_no_difference("Bookmark.count") do
      post import_bookmarks_path, params: { file: fixture_file_upload(file.path, 'application/json') }
    end

    assert_redirected_to bookmarks_path
    assert_match /Skipped 1 duplicate/, flash[:notice]
  end

  test "should handle missing file parameter when signed in" do
    sign_in_as(@user)
    post import_bookmarks_path
    assert_redirected_to bookmarks_path
    assert_equal "Please select a file to import.", flash[:alert]
  end

  test "should handle invalid JSON file when signed in" do
    sign_in_as(@user)
    file = Tempfile.new(['bookmarks', '.json'])
    file.write("This is not JSON")
    file.rewind

    post import_bookmarks_path, params: { file: fixture_file_upload(file.path, 'application/json') }

    assert_redirected_to bookmarks_path
    assert_equal "Invalid JSON file format.", flash[:alert]
  end

  test "should import multiple bookmarks when signed in" do
    sign_in_as(@user)
    file = Tempfile.new(['bookmarks', '.json'])
    file.write([
      {
        "href" => "https://example1.com",
        "description" => "First Site",
        "time" => "2024-12-30T00:16:38Z"
      },
      {
        "href" => "https://example2.com",
        "description" => "Second Site",
        "time" => "2024-12-30T00:16:38Z"
      }
    ].to_json)
    file.rewind

    assert_difference("Bookmark.count", 2) do
      post import_bookmarks_path, params: { file: fixture_file_upload(file.path, 'application/json') }
    end

    assert_redirected_to bookmarks_path
    assert_match /Successfully imported 2 bookmarks/, flash[:notice]
  end

  def teardown
    super
    # Clean up any tempfiles
    ObjectSpace.each_object(Tempfile) do |tempfile|
      tempfile.close!
    end
  end
end
