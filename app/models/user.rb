class User < ApplicationRecord
  has_many :user_preferred_brands, dependent: :destroy
  has_many :preferred_brands, through: :user_preferred_brands, source: :brand

  validates :email, presence: true, uniqueness: true
  validates :preferred_price_range, presence: true

  before_validation { self.email = email.downcase }
end
