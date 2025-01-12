class BookmarksController < ApplicationController
  include ActionView::Helpers::TextHelper

  allow_unauthenticated_access only: %i[ index ]
  before_action :set_owner
  before_action :set_bookmark, only: %i[ edit update destroy ]

  # GET /bookmarks or /bookmarks.json
  def index
    @bookmarks = if authenticated? && Current.user == @owner
      base_scope = @owner.bookmarks
    else
      base_scope = @owner.bookmarks.public_only
    end

    @bookmarks = base_scope.search(params[:query]) if params[:query].present?
  end

  # GET /bookmarks/new
  def new
    @bookmark = Bookmark.new(
      url: params[:url],
      title: params[:title]
    )
    render layout: "popup" if params[:popup] == "true"
  end

  # GET /bookmarks/1/edit
  def edit
  end

  # POST /bookmarks or /bookmarks.json
  def create
    @bookmark = Current.user.bookmarks.build(bookmark_params)

    respond_to do |format|
      if @bookmark.save
        format.html {
          if params[:bookmark][:popup].present?
            # For popup window
            render :create, layout: "popup"
          else
            # For regular form
            redirect_to user_bookmarks_path(Current.user.username), notice: "Bookmark was successfully created."
          end
        }
        format.json { render json: @bookmark, status: :created }
      else
        format.html {
          render :new,
          status: :unprocessable_entity,
          layout: params[:bookmark][:popup] == "true" ? "popup" : "application"
        }
        format.json { render json: @bookmark.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /bookmarks/1 or /bookmarks/1.json
  def update
    respond_to do |format|
      if @bookmark.update(bookmark_params)
        format.html {
          redirect_to user_bookmarks_path(Current.user.username),
            notice: "Bookmark was successfully updated."
        }
        format.json { render json: @bookmark, status: :ok }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @bookmark.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /bookmarks/1 or /bookmarks/1.json
  def destroy
    @bookmark.destroy!

    respond_to do |format|
      format.html {
        redirect_to user_bookmarks_path(Current.user.username),
          status: :see_other, notice: "Bookmark was successfully deleted."
      }
      format.json { head :no_content }
    end
  end

  def import
    return redirect_to_bookmarks(alert: "Please select a file to import.") unless params[:file].present?

    import_bookmarks
  rescue JSON::ParserError
    redirect_to_bookmarks(alert: "Invalid JSON file format.")
  rescue StandardError => e
    redirect_to_bookmarks(alert: "Import failed: #{e.message}")
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_owner
      @owner = User.find_by!(username: params[:username])
    end

    def set_bookmark
      @bookmark = @owner.bookmarks.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def bookmark_params
      params.require(:bookmark).permit(:url, :title, :description, :tags, :is_private)
    end

    def import_bookmarks
      results = BookmarkImporter.new(params[:file], Current.user).import
      redirect_to_bookmarks(notice: import_success_message(results))
    end

    def redirect_to_bookmarks(flash_message)
      redirect_to user_bookmarks_path(Current.user.username), flash_message
    end

    def import_success_message(results)
      "Successfully imported #{pluralize(results.imported, "bookmark")}. " \
      "Skipped #{pluralize(results.skipped, "duplicate")}."
    end
end
