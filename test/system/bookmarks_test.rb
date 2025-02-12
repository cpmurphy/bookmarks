require "application_system_test_case"
require "random/formatter"

class BookmarksTest < ApplicationSystemTestCase
  setup do
    @bookmark = bookmarks(:public_bookmark)
    @private_bookmark = bookmarks(:private_bookmark)
    @user = users(:first_user)
  end

  def random_string
    @prng ||= Random.new
    @prng.hex(10)
  end

  test "visiting the index" do
    visit user_bookmarks_url(@user.username)
    assert_selector "h1", text: "Bookmarks"
  end

  test "should show public bookmarks when not signed in" do
    visit user_bookmarks_url(@user.username)
    assert_text @bookmark.title
    assert_no_text @private_bookmark.title
  end

  test "should show all bookmarks when signed in" do
    sign_in_as(@user)
    visit user_bookmarks_url(@user.username)
    assert_text @bookmark.title
    assert_text @private_bookmark.title
  end

  test "should create bookmark when signed in" do
    sign_in_as(@user)
    visit user_bookmarks_url(@user.username)
    click_on "New bookmark"

    fill_in "Url", with: "http://example.com/new"
    fill_in "Title", with: "New Bookmark"
    fill_in "Description", with: "A new bookmark"
    fill_in "Tags", with: "test,new"
    click_on "Create Bookmark"

    assert_text "Bookmark was successfully created"
  end

  test "should update bookmark when signed in" do
    sign_in_as(@user)
    visit user_bookmarks_url(@user.username)

    within(find_bookmark_card("Example Site")) do
      click_on "Edit"
    end

    fill_in "Title", with: "Updated Title"
    click_on "Update Bookmark"

    assert_text "Bookmark was successfully updated"
    assert_text "Updated Title"
  end

  test "should delete bookmark when signed in" do
    sign_in_as(@user)
    visit user_bookmarks_url(@user.username)
    page.accept_confirm do
      within(find_bookmark_card("Example Site")) do
        click_on "Delete"
      end
    end

    assert_text "Bookmark was successfully deleted"
    assert_no_text "Example Site"
  end

  test "should not show edit/delete buttons when not signed in" do
    visit user_bookmarks_url(@user.username)
    assert_no_text "Edit"
    assert_no_text "Delete"
    assert_no_text "New bookmark"
  end

  test "should redirect to sign in when trying to create bookmark" do
    visit new_user_bookmark_url(@user.username)
    assert_current_path new_session_path
  end

  test "can search bookmarks" do
    visit user_bookmarks_url(@user.username)

    fill_in "query", with: "Example"

    assert_selector ".bookmark-card", text: "Example Site"
    assert_no_selector ".bookmark-card", text: "Private Site"
  end

  test "shows no results message when search finds nothing" do
    visit user_bookmarks_url(@user.username)

    fill_in "query", with: "nonexistent"
    sleep 0.1 # fudge for slow github actions

    assert_no_selector ".bookmark-card"
    assert_text "No bookmarks found"
  end

  test "search respects privacy when not signed in" do
    visit user_bookmarks_url(@user.username)

    fill_in "query", with: "private"

    assert_no_selector ".bookmark-card", text: "Private Site"
  end

  test "search shows private bookmarks when signed in" do
    sign_in_as(@user)
    visit user_bookmarks_url(@user.username)

    fill_in "query", with: "private"

    assert_selector ".bookmark-card", text: "Private Site"
  end

  test "should import bookmarks when signed in" do
    sign_in_as(@user)
    visit tools_path

    # Create a temporary file with bookmark data
    file_path = "tmp/bookmarks-#{$$}#{random_string}.json"
    file = File.open(file_path, "w")
    file.write(<<~JSON)
  [
    {
      "href": "http://example.com/1",
      "description": "Example Site 1",
      "extended": "System testing import bookmark 1",
      "tags": "test,example",
      "is_private": false,
      "time": "2024-01-01T12:00:00Z"
    },
    {
      "href": "http://example.com/2",
      "description": "Example Site 2",
      "extended": "System testing import bookmark 2",
      "tags": "test,example",
      "is_private": false,
      "time": "2024-01-02T12:00:00Z"
    }
  ]
    JSON
    file.close

    # Attach and submit the file
    attach_file find("input[type=file]")[:name], file_path
    click_on "Import"

    # Verify the bookmarks were imported
    assert_text "Successfully imported 2 bookmarks"

    # Visit bookmarks page to verify the imported bookmarks
    click_on "Back to bookmarks"
    assert_text "Example Site 1"
    assert_text "Example Site 2"
    assert_text "System testing import bookmark 1"
    assert_text "System testing import bookmark 2"

    # Clean up
    File.unlink(file_path)
  end

  test "should not allow access to tools when not signed in" do
    visit tools_path
    assert_current_path new_session_path
  end

  test "should handle duplicate URLs during import" do
    sign_in_as(@user)

    # Create a bookmark that will conflict with import
    @user.bookmarks.create!(
      url: "http://example.com/1",
      title: "Existing Site",
      description: "Existing description"
    )

    visit tools_path

    # Create import file with duplicate URL
    file_path = "tmp/bookmarks-#{$$}#{random_string}.json"
    file = File.open(file_path, "w")
    file.write(<<~JSON)
  [
    {
      "href": "http://example.com/1",
      "description": "Example Site 1 duplicate",
      "extended": "System testing import bookmark 1",
      "tags": "test,example",
      "is_private": false,
      "time": "2024-01-01T12:00:00Z"
    },
    {
      "href": "http://example.com/2",
      "description": "Example Site 2",
      "extended": "System testing import bookmark 2",
      "tags": "test,example",
      "is_private": false,
      "time": "2024-01-02T12:00:00Z"
    }
  ]
    JSON
    file.close

    # Attempt import
    attach_file find("input[type=file]")[:name], file_path
    click_on "Import"

    # Verify results
    assert_text "Successfully imported 1 bookmark"
    assert_text "Skipped 1 duplicate"

    # Visit bookmarks page to verify the results
    click_on "Back to bookmarks"
    assert_text "Example Site 2"  # New bookmark should be imported
    assert_text "Existing Site"   # Original bookmark should remain

    # Clean up
    File.unlink(file_path)
  end

  private

  def find_bookmark_card(title)
    find(".bookmark-card", text: title)
  end
end
