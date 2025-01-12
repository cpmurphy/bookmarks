class Bookmark < ApplicationRecord
  belongs_to :user

  validates :url, presence: true, uniqueness: { scope: :user_id }
  validates :title, presence: true

  scope :public_only, -> { where(is_private: [ false, nil ]) }

  default_scope { order(created_at: :desc) }

  def self.search(query)
    where("title LIKE ? OR description LIKE ? OR tags LIKE ?",
          "%#{query}%", "%#{query}%", "%#{query}%")
  end
end
