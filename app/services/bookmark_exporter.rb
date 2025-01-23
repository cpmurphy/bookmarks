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

  def preview(start_id: nil)
    bookmarks = if start_id.present?
      start_bookmark = @user.bookmarks.find(start_id)
      @user.bookmarks.where("created_at >= ?", start_bookmark.created_at)
    else
      @user.bookmarks
    end

    total = bookmarks.count

    preview_bookmarks = if total <= 2
      bookmarks.reorder(created_at: :desc)
    else
      [
        bookmarks.reorder(created_at: :desc).first,
        bookmarks.reorder(created_at: :asc).first
      ]
    end

    {
      total: total,
      bookmarks: preview_bookmarks.map { |b|
        {
          title: b.title,
          date: b.created_at.strftime("%Y-%m-%d")
        }
      }
    }
  end

  def export_netscape
    builder = Nokogiri::HTML::Builder.new(encoding: "UTF-8") do |doc|
      doc.html {
        doc.comment! "DOCTYPE NETSCAPE-Bookmark-file-1"
        doc.meta("HTTP-EQUIV" => "Content-Type", "CONTENT" => "text/html; charset=UTF-8")
        doc.title "Bookmarks"
        doc.h1 "Bookmarks"
        doc.dl {
          doc.p
          @user.bookmarks.each do |bookmark|
            doc.dt {
              doc.a(
                "HREF" => bookmark.url,
                "ADD_DATE" => bookmark.created_at.to_i.to_s,
                "TAGS" => bookmark.tags.presence,
                "DESCRIPTION" => bookmark.description.presence
              ) { doc.text bookmark.title }
            }
          end
        }
      }
    end

    builder.to_html
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
