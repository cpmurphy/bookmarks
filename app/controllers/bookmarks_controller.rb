class BookmarksController < ApplicationController
  allow_unauthenticated_access only: %i[ index ]
  before_action :set_bookmark, only: %i[ edit update destroy ]

  # GET /bookmarks or /bookmarks.json
  def index
    @bookmarks = if authenticated?
      base_scope = Bookmark.all
    else
      base_scope = Bookmark.where(private: [ false, nil ])
    end

    @bookmarks = base_scope.search(params[:query]) if params[:query].present?
  end

  # GET /bookmarks/new
  def new
    @bookmark = Bookmark.new
  end

  # GET /bookmarks/1/edit
  def edit
  end

  # POST /bookmarks or /bookmarks.json
  def create
    @bookmark = Bookmark.new(bookmark_params)

    respond_to do |format|
      if @bookmark.save
        format.html { redirect_to bookmarks_path, notice: "Bookmark was successfully created." }
        format.json { render json: @bookmark, status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @bookmark.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /bookmarks/1 or /bookmarks/1.json
  def update
    respond_to do |format|
      if @bookmark.update(bookmark_params)
        format.html { redirect_to bookmarks_path, notice: "Bookmark was successfully updated." }
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
      format.html { redirect_to bookmarks_path, status: :see_other, notice: "Bookmark was successfully deleted." }
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
    def set_bookmark
      @bookmark = Bookmark.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def bookmark_params
      params.expect(bookmark: [ :url, :title, :description, :tags ])
    end

    def import_bookmarks
      results = BookmarkImporter.new(params[:file]).import
      redirect_to_bookmarks(notice: import_success_message(results))
    end

    def redirect_to_bookmarks(flash_message)
      redirect_to bookmarks_path, flash_message
    end

    def import_success_message(results)
      "Successfully imported #{results.imported} bookmarks. " \
      "Skipped #{results.skipped} duplicates."
    end
end
