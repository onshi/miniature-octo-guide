FactoryBot.define do
  factory :user do
    sequence :email do |n|
      "yolo#{n}@example.com"
    end

    preferred_price_range { (35_000..40_000) }
  end
end
