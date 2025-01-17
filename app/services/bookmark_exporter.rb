class BookmarkExporter
  def initialize(user)
    @user = user
  end

  def search(query, limit: 10)
    @user.bookmarks
      .where("title LIKE ? OR url LIKE ?", "%#{query}%", "%#{query}%")
      .order(created_at: :desc)
      .limit(limit)
      .select(:id, :title, :url, :created_at)
      .map { |b| format_search_result(b) }
  end

  def export(start_id: nil)
    bookmarks = if start_id.present?
      start_bookmark = @user.bookmarks.find(start_id)
      @user.bookmarks.where("created_at >= ?", start_bookmark.created_at)
    else
      @user.bookmarks
    end

    bookmarks.map { |bookmark| format_bookmark(bookmark) }
  end

  private

  def format_search_result(bookmark)
    {
      id: bookmark.id,
      title: bookmark.title,
      url: bookmark.url,
      date: bookmark.created_at.strftime("%Y-%m-%d")
    }
  end

  def format_bookmark(bookmark)
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
end
