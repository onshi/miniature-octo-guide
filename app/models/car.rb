class Car < ApplicationRecord
  belongs_to :brand

  validates :model, presence: true
  validates :price, presence: true, numericality: {greater_than_or_equal_to: 0}
end
