require "nokogiri"

class NetscapeBookmarkImporter
  Results = Struct.new(:imported, :skipped)

  def initialize(file, user)
    @file = file
    @user = user
    @imported = 0
    @skipped = 0
  end

  def import
    doc = Nokogiri::HTML(@file.read)

    ActiveRecord::Base.transaction do
      doc.css("a").each do |link|
        process_bookmark(link)
      end
    end

    Results.new(@imported, @skipped)
  end

  private

  def process_bookmark(link)
    url = link["href"]
    return unless url.present?

    bookmark = Bookmark.find_by(url: url)

    if bookmark
      @skipped += 1
    else
      create_bookmark(link)
      @imported += 1
    end
  end

  def create_bookmark(link)
    title = link.text.presence || "[no title]"
    description = link["description"] || ""
    tags = link["tags"] || ""
    created_at = Time.zone.at(link["add_date"].to_i) if link["add_date"].present?

    Bookmark.create!(
      user: @user,
      url: link["href"],
      title: title,
      description: description,
      tags: tags,
      created_at: created_at || Time.zone.now
    )
  end
end
