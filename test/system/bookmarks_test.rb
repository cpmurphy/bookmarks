require "application_system_test_case"

class BookmarksTest < ApplicationSystemTestCase
  setup do
    @bookmark = bookmarks(:one)
    @private_bookmark = bookmarks(:private_bookmark)
    @user = users(:one)
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

  private

  def find_bookmark_card(title)
    find(".bookmark-card", text: title)
  end
end
