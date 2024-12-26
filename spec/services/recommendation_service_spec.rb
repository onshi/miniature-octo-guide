require "rails_helper"

describe RecommendationService do
  subject { described_class.call(user_id, query, price_min, price_max, page, per_page) }

  let(:user) { create(:user) }
  let(:user_id) { user.id }
  let(:query) { "volk" }
  let(:price_min) { 10_000 }
  let(:price_max) { 40_000 }
  let(:car) { create(:car, brand: create(:brand), price: 37_000) }
  let(:brand) { car.brand }
  let(:page) { 1 }
  let(:per_page) { 20 }
  let(:expected_response) do
    [
      {
        brand: {
          id: brand.id,
          name: "Volkswagen"
        },
        id: car.id,
        label: nil,
        model: "Golf",
        price: 37000,
        rank_score: 0.42
      }
    ]
  end

  before do
    car

    Rails.cache.clear

    expect(Rails.cache).to receive(:fetch).with("recommended_cars-#{user_id}", expires_in: 24.hours).and_call_original
    expect(BravadoRecommendationClient).to(
      receive(:get_cars).with(user_id).once.and_return([{"car_id" => car.id, "rank_score" => 0.42}])
    )
  end

  it "returns proper response" do
    expect(subject).to eq(expected_response)
  end

  context "with user preferred brand" do
    let(:expected_response) do
      [
        {
          brand: {
            id: brand.id,
            name: "Volkswagen"
          },
          id: car.id,
          label: "perfect_match",
          model: "Golf",
          price: 37000,
          rank_score: 0.42
        }
      ]
    end

    before { create(:user_preferred_brand, user: user, brand: brand) }

    it "returns proper response" do
      expect(subject).to eq(expected_response)
    end
  end
end
