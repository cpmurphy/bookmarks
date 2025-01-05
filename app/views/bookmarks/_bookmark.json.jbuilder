json.extract! bookmark, :id, :url, :title, :description, :tags, :created_at, :updated_at
json.url bookmark_url(bookmark, format: :json)
