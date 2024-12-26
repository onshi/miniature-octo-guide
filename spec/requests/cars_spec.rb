require "rails_helper"

RSpec.describe "Cars API", type: :request, skip_request_specs: true do
  let(:recommendation_service_response) do
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
  let(:user) { User.first }
  let(:user_id) { user.id }
  let(:headers) { {"Content-Type" => "application/json"} }

  before(:context) do
    ["users", "user_preferred_brands", "cars", "brands"].each do |table|
      sequence_name = ActiveRecord::Base.connection.select_value("SELECT pg_get_serial_sequence('#{table}', 'id')")
      ActiveRecord::Base.connection.execute("ALTER SEQUENCE #{sequence_name} RESTART WITH 1")
    end

    Rails.application.load_seed
  end

  after(:context) do
    [UserPreferredBrand, User, Car, Brand].each(&:delete_all)
  end

  before do
    stub_request(
      :get,
      BravadoRecommendationClient::API_BASE_URL
    ).with(
      query: {user_id: user_id}
    ).to_return_json(
      body: recommendation_service_response
    )
  end

  describe "GET /v1/cars" do
    context "with proper params" do
      let(:params) do
        {
          user_id: user.id,
          page: 1
        }
      end
      let(:expected_response) do
        [
          {
            id: 179,
            brand: {
              id: 39,
              name: "Volkswagen"
            },
            model: "Derby",
            price: 37230,
            rank_score: 0.945,
            label: "perfect_match"
          },
          {
            id: 5,
            brand: {
              id: 2,
              name: "Alfa Romeo"
            },
            model: "Arna",
            price: 39938,
            rank_score: 0.4552,
            label: "perfect_match"
          },
          {
            id: 180,
            brand: {
              id: 39,
              name: "Volkswagen"
            },
            model: "e-Golf",
            price: 35131,
            rank_score: nil,
            label: "perfect_match"
          },
          {
            id: 181,
            brand: {
              id: 39,
              name: "Volkswagen"
            },
            model: "Amarok",
            price: 31743,
            rank_score: nil,
            label: "good_match"
          },
          {
            id: 186,
            brand: {
              id: 2,
              name: "Alfa Romeo"
            },
            model: "Brera",
            price: 40938,
            rank_score: nil,
            label: "good_match"
          },
          {
            id: 97,
            brand: {
              id: 20,
              name: "Lexus"
            },
            model: "IS 220",
            price: 39858,
            rank_score: 0.9489,
            label: nil
          },
          {
            id: 36,
            brand: {
              id: 6,
              name: "Buick"
            },
            model: "GL 8",
            price: 86657,
            rank_score: 0.7068,
            label: nil
          },
          {
            id: 13,
            brand: {
              id: 3,
              name: "Audi"
            },
            model: "90",
            price: 56959,
            rank_score: 0.567,
            label: nil
          },
          {
            id: 103,
            brand: {
              id: 22,
              name: "Lotus"
            },
            model: "Eclat",
            price: 48953,
            rank_score: 0.4729,
            label: nil
          },
          {
            id: 177,
            brand: {
              id: 38,
              name: "Toyota"
            },
            model: "Allion",
            price: 40687,
            rank_score: 0.1657,
            label: nil
          },
          {
            id: 32,
            brand: {
              id: 6,
              name: "Buick"
            },
            model: "Verano",
            price: 21739,
            rank_score: 0.0967,
            label: nil
          },
          {
            id: 176,
            brand: {
              id: 37,
              name: "Suzuki"
            },
            model: "Kizashi",
            price: 40181,
            rank_score: 0.0353,
            label: nil
          },
          {
            id: 113,
            brand: {
              id: 24,
              name: "Mazda"
            },
            model: "3",
            price: 1542,
            rank_score: nil,
            label: nil
          },
          {
            id: 100,
            brand: {
              id: 20,
              name: "Lexus"
            },
            model: "RX 300",
            price: 1972,
            rank_score: nil,
            label: nil
          },
          {
            id: 184,
            brand: {
              id: 40,
              name: "Volvo"
            },
            model: "610",
            price: 3560,
            rank_score: nil,
            label: nil
          },
          {
            id: 142,
            brand: {
              id: 31,
              name: "Ram"
            },
            model: "Promaster City",
            price: 3687,
            rank_score: nil,
            label: nil
          },
          {
            id: 120,
            brand: {
              id: 26,
              name: "Mercury"
            },
            model: "Marauder",
            price: 3990,
            rank_score: nil,
            label: nil
          },
          {
            id: 109,
            brand: {
              id: 23,
              name: "Maserati"
            },
            model: "Levante",
            price: 4243,
            rank_score: nil,
            label: nil
          },
          {
            id: 89,
            brand: {
              id: 16,
              name: "Infiniti"
            },
            model: "M25",
            price: 4372,
            rank_score: nil,
            label: nil
          },
          {
            id: 164,
            brand: {
              id: 35,
              name: "Smart"
            },
            model: "Forfour",
            price: 4391,
            rank_score: nil,
            label: nil
          }
        ].to_json
      end

      it "returns expected response" do
        get "/v1/cars", params: params, headers: headers

        expect(response.status).to eq(200)
        expect(response.body).to eq(expected_response)
      end
    end

    context "without required user_id" do
      it "returns unprocessable_entity status code" do
        get "/v1/cars", params: {}, headers: headers

        expect(response.status).to eq(422)
        expect(JSON.parse(response.body)).to eq({"error" => "missing required user_id param"})
      end
    end

    context "with query param" do
      let(:params) do
        {
          user_id: user.id,
          page: 1,
          query: "volk"
        }
      end
      let(:expected_response) do
        [
          {
            id: 179,
            brand: {
              id: 39,
              name: "Volkswagen"
            },
            model: "Derby",
            price: 37230,
            rank_score: 0.945,
            label: "perfect_match"
          },
          {
            id: 180,
            brand: {
              id: 39,
              name: "Volkswagen"
            },
            model: "e-Golf",
            price: 35131,
            rank_score: nil,
            label: "perfect_match"
          },
          {
            id: 181,
            brand: {
              id: 39,
              name: "Volkswagen"
            },
            model: "Amarok",
            price: 31743,
            rank_score: nil,
            label: "good_match"
          }
        ].to_json
      end

      it "returns expected response" do
        get "/v1/cars", params: params, headers: headers

        expect(response.status).to eq(200)
        expect(response.body).to eq(expected_response)
      end
    end

    context "with query param and price_max and price_min" do
      let(:params) do
        {
          user_id: user.id,
          page: 1,
          query: "volk",
          price_max: 36_000,
          price_min: 35_000
        }
      end
      let(:expected_response) do
        [
          {
            id: 180,
            brand: {
              id: 39,
              name: "Volkswagen"
            },
            model: "e-Golf",
            price: 35131,
            rank_score: nil,
            label: "perfect_match"
          }
        ].to_json
      end

      it "returns expected response" do
        get "/v1/cars", params: params, headers: headers

        expect(response.status).to eq(200)
        expect(response.body).to eq(expected_response)
      end
    end
  end
end
