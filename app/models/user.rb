class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :bookmarks, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true
  validates :username, presence: true, uniqueness: true,
                      format: {
                        with: /\A[a-zA-Z0-9_]+\z/,
                        message: "can only contain letters, numbers, and underscores"
                      },
                      length: { minimum: 3, maximum: 20 }
end
