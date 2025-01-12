class BookmarkImporter
  Results = Struct.new(:imported, :skipped)

  def initialize(file, user)
    @file = file
    @user = user
    @imported = 0
    @skipped = 0
  end

  def import
    ActiveRecord::Base.transaction do
      JSON.parse(@file.read).each do |item|
        process_bookmark(item)
      end
    end

    Results.new(@imported, @skipped)
  end

  private

  def process_bookmark(item)
    bookmark = Bookmark.find_by(url: item["href"])

    if bookmark
      @skipped += 1
    else
      create_bookmark(item)
      @imported += 1
    end
  end

  def create_bookmark(item)
    title = item["description"]
    if !title.present?
        title = "[no title]"
    end

    description = item["extended"]
    tags = item["tags"].presence || ""
    if item["time"].present?
        created_at = Time.zone.parse(item["time"])
    else
        created_at = Time.zone.now
    end

    Bookmark.create!(
      user: @user,
      url: item["href"],
      title: title,
      description: description,
      tags: tags,
      created_at: created_at
    )
  end
end
