require "test_helper"

class ToolsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:first_user)
  end

  test "should get show when signed in" do
    sign_in_as(@user)
    get tools_path

    assert_response :success
  end

  test "should not get show when not signed in" do
    get tools_path

    assert_redirected_to new_session_path
  end

  test "should import bookmarks from JSON file when signed in" do
    sign_in_as(@user)
    # Create a temp file with test JSON data
    file = Tempfile.new([ "bookmarks", ".json" ])
    file.write([ {
      "href" => "https://example.com",
      "description" => "Example Site",
      "extended" => "A test bookmark",
      "tags" => "test,example",
      "time" => "2024-12-30T00:16:38Z"
    } ].to_json)
    file.rewind

    assert_difference("Bookmark.count") do
      post import_tools_path,
        params: { file: fixture_file_upload(file.path, "application/json") }
    end

    assert_redirected_to tools_path
    assert_match /Successfully imported 1 bookmark/, flash[:notice]
  end

  test "should import data from JSON file when signed in" do
    sign_in_as(@user)
    # Create a temp file with test JSON data
    file = Tempfile.new([ "bookmarks", ".json" ])
    file.write([ {
      "href" => "https://example.com",
      "description" => "Example Site",
      "extended" => "A test bookmark",
      "tags" => "test,example",
      "time" => "2024-12-30T00:16:38Z"
    } ].to_json)
    file.rewind

    post import_tools_path,
      params: { file: fixture_file_upload(file.path, "application/json") }

    # Verify the imported bookmark data
    bookmark = Bookmark.last

    assert_equal [ "https://example.com", "Example Site", "A test bookmark", "test,example", Time.zone.parse("2024-12-30T00:16:38Z") ],
      [ bookmark.url, bookmark.title, bookmark.description, bookmark.tags, bookmark.created_at ]
  end

  test "should handle duplicate URLs during import when signed in" do
    # First create a bookmark
    Bookmark.create!(
      url: "https://example.com",
      title: "Existing Bookmark",
      user: @user
    )

    # Try to import the same URL
    file = Tempfile.new([ "bookmarks", ".json" ])
    file.write([ {
      "href" => "https://example.com",
      "description" => "Duplicate Site",
      "time" => "2024-12-30T00:16:38Z"
    } ].to_json)
    file.rewind

    sign_in_as(@user)
    assert_no_difference("Bookmark.count") do
      post import_tools_path,
        params: { file: fixture_file_upload(file.path, "application/json") }
    end

    assert_redirected_to tools_path
    assert_match /Skipped 1 duplicate/, flash[:notice]
  end

  test "should handle missing file parameter when signed in" do
    sign_in_as(@user)
    post import_tools_path

    assert_redirected_to tools_path
    assert_equal "Please select a file to import.", flash[:alert]
  end

  test "should handle invalid JSON file when signed in" do
    sign_in_as(@user)
    file = Tempfile.new([ "bookmarks", ".json" ])
    file.write("This is not JSON")
    file.rewind

    post import_tools_path,
      params: { file: fixture_file_upload(file.path, "application/json") }

    assert_redirected_to tools_path
    assert_equal "Invalid JSON file format.", flash[:alert]
  end

  test "should import multiple bookmarks when signed in" do
    sign_in_as(@user)
    file = Tempfile.new([ "bookmarks", ".json" ])
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
      post import_tools_path,
        params: { file: fixture_file_upload(file.path, "application/json") }
    end

    assert_redirected_to tools_path
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
