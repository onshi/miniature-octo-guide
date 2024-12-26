FactoryBot.define do
  factory :user_preferred_brand do
    association :user
    association :brand
  end
end
