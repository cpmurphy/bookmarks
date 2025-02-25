require "test_helper"

class BookmarksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:first_user)
    @bookmark = bookmarks(:public_bookmark)
    @private_bookmark = bookmarks(:private_bookmark)
  end

  test "should get index" do
    get user_bookmarks_url(@user.username)

    assert_response :success
    assert_includes @response.body, @bookmark.title
    assert_not_includes @response.body, @private_bookmark.title
  end

  test "should get index with all bookmarks when signed in" do
    sign_in_as(@user)
    get user_bookmarks_url(@user.username)

    assert_response :success
    assert_includes @response.body, @bookmark.title
    assert_includes @response.body, @private_bookmark.title
  end

  test "should get new when signed in" do
    sign_in_as(@user)
    get new_user_bookmark_path(@user.username)

    assert_response :success
  end

  test "should not get new when not signed in" do
    get new_user_bookmark_path(@user.username)

    assert_redirected_to new_session_path
  end

  test "should create bookmark when signed in" do
    sign_in_as(@user)
    assert_difference("Bookmark.count") do
      post user_bookmarks_path(@user.username), params: {
        bookmark: {
          url: "http://example.com/new",
          title: "New Bookmark"
        }
      }
    end

    assert_redirected_to user_bookmarks_url(@user.username)
  end

  test "should get edit" do
    sign_in_as(@user)
    get edit_user_bookmark_path(@user.username, @bookmark)

    assert_response :success
  end

  test "should update bookmark" do
    sign_in_as(@user)
    @bookmark.url = "http://example.com/3"
    patch user_bookmark_path(@user.username, @bookmark), params: {
      bookmark: {
        description: @bookmark.description,
        tags: @bookmark.tags,
        title: @bookmark.title,
        url: @bookmark.url
      }
    }

    assert_redirected_to user_bookmarks_path(@user.username)
  end

  test "should destroy bookmark when signed in" do
    sign_in_as(@user)
    assert_difference("Bookmark.count", -1) do
      delete user_bookmark_path(@user.username, @bookmark)
    end

    assert_redirected_to user_bookmarks_path(@user.username)
  end
end
