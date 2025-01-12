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
    bookmark = Bookmark.find_or_initialize_by(url: item["href"])

    if bookmark.new_record?
      create_bookmark(bookmark, item)
      @imported += 1
    else
      @skipped += 1
    end
  end

  def create_bookmark(bookmark, item)
    bookmark.update!(
      user: @user,
      title: item["description"],
      description: item["extended"],
      tags: item["tags"].presence || "",
      created_at: Time.zone.parse(item["time"])
    )
  end
end
