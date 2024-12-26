FactoryBot.define do
  factory :car do
    model { "Golf" }
    price { rand(100_000) }

    association :brand
  end
end
