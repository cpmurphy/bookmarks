class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> {
    redirect_to new_session_url, alert: "Try again later."
  }

  def new
    if authenticated? && Current.user
      redirect_to user_bookmarks_path(Current.user.username)
    end
  end

  def create
    user = User.authenticate_by(email_address: params[:email_address], password: params[:password])

    if user
      start_new_session_for user
      redirect_to user_bookmarks_path(user.username), notice: "Signed in successfully"
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: "Signed out successfully"
  end
end
