class Bookmark < ApplicationRecord
  validates :url, presence: true, uniqueness: true
  # ... other validations ...
end
