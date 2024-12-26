class Brand < ApplicationRecord
  has_many :cars, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  before_validation { self.name = name.titleize }
end
