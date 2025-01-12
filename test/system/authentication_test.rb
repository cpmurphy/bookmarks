require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  setup do
    @user = users(:first_user)
  end

  test "signing in and out" do
    # First sign in
    visit root_url
    fill_in "Enter your email address", with: "first_user@example.com"
    fill_in "Enter your password", with: "password"
    click_on "Sign in"

    assert_text "Signed in successfully"
    assert_current_path user_bookmarks_path(@user.username)

    # Then sign out
    click_on "Sign out"

    assert_text "Signed out successfully"
    assert_no_text "Sign out"
    assert_current_path new_session_path

    # Verify we're actually signed out by checking for sign in button
    assert_selector "input[value='Sign in']"
  end

  test "cannot access private content when signed out" do
    # First sign in
    sign_in_as(@user)
    assert_current_path user_bookmarks_path(@user.username)

    # Sign out
    click_on "Sign out"

    # Try to access private bookmarks
    visit user_bookmarks_path(@user.username)
    assert_no_text "Private Site"
  end
end
