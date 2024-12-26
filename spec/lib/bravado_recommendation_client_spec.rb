require "rails_helper"

describe BravadoRecommendationClient do
  subject { described_class.new }

  let(:api_url) { "https://bravado-images-production.s3.amazonaws.com/recomended_cars.json" }

  it "has correct BASE URL" do
    expect(described_class::API_BASE_URL).to eq(api_url)
  end

  describe "GET .get_cars(user_id)" do
    let(:user_id) { 1 }
    let(:expected_response) do
      [
        {"car_id" => 179, "rank_score" => 0.945},
        {"car_id" => 5, "rank_score" => 0.4552},
        {"car_id" => 13, "rank_score" => 0.567},
        {"car_id" => 97, "rank_score" => 0.9489},
        {"car_id" => 32, "rank_score" => 0.0967},
        {"car_id" => 176, "rank_score" => 0.0353},
        {"car_id" => 177, "rank_score" => 0.1657},
        {"car_id" => 36, "rank_score" => 0.7068},
        {"car_id" => 103, "rank_score" => 0.4729}
      ]
    end

    context "with valid query" do
      before do
        stub_request(
          :get,
          api_url
        ).with(
          query: {user_id: user_id}
        ).to_return_json(
          body: expected_response
        )
      end

      it "returns array of recommendations" do
        expect(described_class.get_cars(user_id)).to eq(expected_response)
      end
    end

    context "with request timeout" do
      before do
        stub_request(:any, api_url).with(query: {user_id: user_id}).to_timeout
      end

      it "raises UnavailableError" do
        expect { described_class.get_cars(user_id) }.to raise_error(described_class::UnavailableError)
      end
    end
  end
end
