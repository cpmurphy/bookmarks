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
