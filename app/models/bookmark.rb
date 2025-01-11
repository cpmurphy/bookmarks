class Bookmark < ApplicationRecord
  validates :url, presence: true, uniqueness: true
  # ... other validations ...

  def self.search(query)
    where("title LIKE ? OR description LIKE ? OR tags LIKE ?",
          "%#{query}%", "%#{query}%", "%#{query}%")
  end
end
