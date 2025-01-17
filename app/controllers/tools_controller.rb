class ToolsController < ApplicationController
  include Authentication
  include ActionView::Helpers::TextHelper
  require 'digest'

  def show
  end

  def import
    return redirect_to_tools(alert: "Please select a file to import.") unless params[:file].present?

    import_bookmarks
  rescue JSON::ParserError
    redirect_to_tools(alert: "Invalid JSON file format.")
  rescue StandardError => e
    redirect_to_tools(alert: "Import failed: #{e.message}")
  end

  def export
    @bookmarks = if params[:start_id].present?
      start_bookmark = Current.user.bookmarks.find(params[:start_id])
      Current.user.bookmarks.where("created_at >= ?", start_bookmark.created_at)
    else
      Current.user.bookmarks
    end

    bookmarks_data = @bookmarks.map do |bookmark|
      {
        href: bookmark.url,
        description: bookmark.title,
        extended: bookmark.description,
        meta: "",
        hash: Digest::MD5.hexdigest(bookmark.url),
        time: bookmark.created_at.iso8601,
        shared: bookmark.is_private ? "no" : "yes",
        toread: "no",
        tags: bookmark.tags
      }
    end

    respond_to do |format|
      format.json do
        send_data bookmarks_data.to_json,
          filename: "bookmarks_export_#{Time.current.strftime("%Y%m%d")}.json",
          type: :json
      end
    end
  end

  def search
    @bookmarks = Current.user.bookmarks
      .where("title LIKE ? OR url LIKE ?", "%#{params[:query]}%", "%#{params[:query]}%")
      .order(created_at: :desc)
      .limit(10)
      .select(:id, :title, :url, :created_at)

    render json: @bookmarks.map { |b|
      {
        id: b.id,
        title: b.title,
        url: b.url,
        date: b.created_at.strftime("%Y-%m-%d")
      }
    }
  end

  private

  def import_bookmarks
    results = BookmarkImporter.new(params[:file], Current.user).import
    redirect_to_tools(notice: import_success_message(results))
  end

  def redirect_to_tools(flash_message)
    redirect_to tools_path, flash_message
  end

  def import_success_message(results)
    "Successfully imported #{pluralize(results.imported, "bookmark")}. " \
    "Skipped #{pluralize(results.skipped, "duplicate")}."
  end
end
