class ToolsController < ApplicationController
  include Authentication
  include ActionView::Helpers::TextHelper

  def show
  end

  def import
    return redirect_to_tools(alert: "Please select a file to import.") unless params[:file].present?

    importer = case params[:file].content_type
    when "application/json"
      BookmarkImporter.new(params[:file], Current.user)
    when "text/html"
      NetscapeBookmarkImporter.new(params[:file], Current.user)
    else
      return redirect_to_tools(alert: "Unsupported file format. Please use JSON or HTML.")
    end

    results = importer.import
    redirect_to_tools(notice: import_success_message(results))

  rescue JSON::ParserError
    redirect_to_tools(alert: "Invalid JSON file format.")
  rescue Nokogiri::HTML::SyntaxError
    redirect_to_tools(alert: "Invalid HTML bookmark file format.")
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

  def redirect_to_tools(flash_message)
    redirect_to tools_path, flash_message
  end

  def import_success_message(results)
    "Successfully imported #{pluralize(results.imported, "bookmark")}. " \
    "Skipped #{pluralize(results.skipped, "duplicate")}."
  end
end
