class BookmarksController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]
  before_action :set_bookmark, only: %i[ show edit update destroy ]

  # GET /bookmarks or /bookmarks.json
  def index
    @bookmarks = if authenticated?
      Bookmark.all
    else
      Bookmark.where(private: [false, nil])
    end
  end

  # GET /bookmarks/1 or /bookmarks/1.json
  def show
    unless authenticated? || !@bookmark.private?
      redirect_to bookmarks_path, alert: "You must be signed in to view private bookmarks"
    end
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
        format.html { redirect_to @bookmark, notice: "Bookmark was successfully created." }
        format.json { render :show, status: :created, location: @bookmark }
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
        format.html { redirect_to @bookmark, notice: "Bookmark was successfully updated." }
        format.json { render :show, status: :ok, location: @bookmark }
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
      format.html { redirect_to bookmarks_path, status: :see_other, notice: "Bookmark was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def import
    if params[:file].present?
      json_data = JSON.parse(params[:file].read)
      imported = 0
      skipped = 0

      ActiveRecord::Base.transaction do
        json_data.each do |item|
          bookmark = Bookmark.find_or_initialize_by(url: item['href'])
          if bookmark.new_record?
            bookmark.update!(
              title: item['description'],
              description: item['extended'],
              tags: item['tags'].presence || '',
              created_at: Time.zone.parse(item['time'])
            )
            imported += 1
          else
            skipped += 1
          end
        end
      end

      redirect_to bookmarks_path,
        notice: "Successfully imported #{imported} bookmarks. Skipped #{skipped} duplicates."
    else
      redirect_to bookmarks_path, alert: "Please select a file to import."
    end
  rescue JSON::ParserError
    redirect_to bookmarks_path, alert: "Invalid JSON file format."
  rescue => e
    redirect_to bookmarks_path, alert: "Import failed: #{e.message}"
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

end
