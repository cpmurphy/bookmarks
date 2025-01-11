require "application_system_test_case"

class BookmarksTest < ApplicationSystemTestCase
  setup do
    @bookmark = bookmarks(:one)
    @private_bookmark = bookmarks(:private)
    @user = users(:one)
  end

  test "visiting the index" do
    visit bookmarks_url
    assert_selector "h1", text: "Bookmarks"
  end

  test "should show public bookmarks when not signed in" do
    visit bookmarks_url
    assert_text @bookmark.title
    assert_no_text @private_bookmark.title
  end

  test "should show all bookmarks when signed in" do
    sign_in_as(@user)
    visit bookmarks_url
    assert_text @bookmark.title
    assert_text @private_bookmark.title
  end

  test "should create bookmark when signed in" do
    sign_in_as(@user)
    visit bookmarks_url
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
    visit bookmarks_url

    within("#bookmark_#{@bookmark.id}") do
      click_on "Edit"
    end

    fill_in "Title", with: "Updated Title"
    click_on "Update Bookmark"

    assert_text "Bookmark was successfully updated"
    assert_text "Updated Title"
  end

  test "should destroy bookmark when signed in" do
    sign_in_as(@user)
    visit bookmarks_url
    page.accept_confirm do
      within("#bookmark_#{@bookmark.id}") do
        click_on "Delete"
      end
    end

    assert_text "Bookmark was successfully destroyed"
  end

  test "should not show edit/delete buttons when not signed in" do
    visit bookmarks_url
    assert_no_text "Edit"
    assert_no_text "Delete"
    assert_no_text "New bookmark"
  end

  test "should redirect to sign in when trying to create bookmark" do
    visit new_bookmark_url
    assert_current_path new_session_path
    assert_text "Please sign in to modify bookmarks"
  end
end
