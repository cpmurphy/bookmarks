class ToolsController < ApplicationController
  include Authentication
  include ActionView::Helpers::TextHelper

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
    exporter = BookmarkExporter.new(Current.user)
    bookmarks_data = exporter.export(start_id: params[:start_id])

    respond_to do |format|
      format.json do
        send_data bookmarks_data.to_json,
          filename: "bookmarks_export_#{Time.current.strftime("%Y%m%d")}.json",
          type: :json
      end
    end
  end

  def search
    exporter = BookmarkExporter.new(Current.user)
    render json: exporter.search(params[:query])
  end

  def preview_export
    exporter = BookmarkExporter.new(Current.user)
    preview_data = exporter.preview(start_id: params[:start_id])

    render json: preview_data
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
