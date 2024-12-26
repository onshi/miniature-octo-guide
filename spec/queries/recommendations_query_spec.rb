require "rails_helper"

describe RecommendationsQuery do
  subject(:build) { described_class.build(ai_recommendations, brand_name) }

  let(:ai_recommendations) do
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
  let(:brand_name) { "" }
  let(:expected_sql) do
    <<~SQL.gsub(/^\s+/, "")
      SELECT cars.*, brands.name AS brand_name,
      CASE
        WHEN
        cars.brand_id IN (
          SELECT brand_id FROM user_preferred_brands WHERE user_id = :user_id
        )
        AND cars.price::INT8 <@ (SELECT preferred_price_range FROM users where id = :user_id) THEN 'perfect_match'
        WHEN cars.brand_id IN (
          SELECT brand_id FROM user_preferred_brands WHERE user_id = :user_id
        ) THEN 'good_match'
        ELSE NULL
      END AS label,
      COALESCE(
        (
          array(
            SELECT rank_score FROM (
              VALUES (179, 0.945),(5, 0.4552),(13, 0.567),(97, 0.9489),(32, 0.0967),(176, 0.0353),(177, 0.1657),(36, 0.7068),(103, 0.4729)
            ) AS recommendations(car_id, rank_score)
            WHERE recommendations.car_id = cars.id
          )::float[])[1],
        NULL
      ) AS rank_score
      FROM cars
      INNER JOIN brands ON brands.id = cars.brand_id
      ORDER BY
      CASE
        WHEN
        cars.brand_id IN (
          SELECT brand_id FROM user_preferred_brands WHERE user_id = :user_id
        )
        AND cars.price::INT8 <@ (SELECT preferred_price_range FROM users where id = :user_id) THEN 1
        WHEN cars.brand_id IN (SELECT brand_id FROM user_preferred_brands WHERE user_id = user_id) THEN 2
        ELSE 3
      END ASC,
      rank_score DESC NULLS LAST,
      price ASC
      LIMIT :limit
      OFFSET :offset
      ;
    SQL
  end

  context "without brand_name" do
    it "renders expected sql" do
      expect(build).to eq(expected_sql)
    end
  end

  context "with brand_name" do
    let(:brand_name) { "Volkswagen" }
    let(:expected_sql) do
      <<~SQL.gsub(/^\s+/, "")
        SELECT cars.*, brands.name AS brand_name,
        CASE
          WHEN
          cars.brand_id IN (
            SELECT brand_id FROM user_preferred_brands WHERE user_id = :user_id
          )
          AND cars.price::INT8 <@ (SELECT preferred_price_range FROM users where id = :user_id) THEN 'perfect_match'
          WHEN cars.brand_id IN (
            SELECT brand_id FROM user_preferred_brands WHERE user_id = :user_id
          ) THEN 'good_match'
          ELSE NULL
        END AS label,
        COALESCE(
          (
            array(
              SELECT rank_score FROM (
                VALUES (179, 0.945),(5, 0.4552),(13, 0.567),(97, 0.9489),(32, 0.0967),(176, 0.0353),(177, 0.1657),(36, 0.7068),(103, 0.4729)
              ) AS recommendations(car_id, rank_score)
              WHERE recommendations.car_id = cars.id
            )::float[])[1],
          NULL
        ) AS rank_score
        FROM cars
        INNER JOIN brands ON brands.id = cars.brand_id
        WHERE brands.name ILIKE '%Volkswagen%' ORDER BY
        CASE
          WHEN
          cars.brand_id IN (
            SELECT brand_id FROM user_preferred_brands WHERE user_id = :user_id
          )
          AND cars.price::INT8 <@ (SELECT preferred_price_range FROM users where id = :user_id) THEN 1
          WHEN cars.brand_id IN (SELECT brand_id FROM user_preferred_brands WHERE user_id = user_id) THEN 2
          ELSE 3
        END ASC,
        rank_score DESC NULLS LAST,
        price ASC
        LIMIT :limit
        OFFSET :offset
        ;
      SQL
    end

    it "renders sql with WHERE clause" do
      expect(build).to eq(expected_sql)
    end
  end

  context "with brand_name, price_min and price_max" do
    subject(:build) { described_class.build(ai_recommendations, brand_name, price_min, price_max) }

    let(:brand_name) { "Volkswagen" }
    let(:price_min) { 10_000 }
    let(:price_max) { 20_000 }
    let(:expected_sql) do
      <<~SQL.gsub(/^\s+/, "")
        SELECT cars.*, brands.name AS brand_name,
        CASE
          WHEN
          cars.brand_id IN (
            SELECT brand_id FROM user_preferred_brands WHERE user_id = :user_id
          )
          AND cars.price::INT8 <@ (SELECT preferred_price_range FROM users where id = :user_id) THEN 'perfect_match'
          WHEN cars.brand_id IN (
            SELECT brand_id FROM user_preferred_brands WHERE user_id = :user_id
          ) THEN 'good_match'
          ELSE NULL
        END AS label,
        COALESCE(
          (
            array(
              SELECT rank_score FROM (
                VALUES (179, 0.945),(5, 0.4552),(13, 0.567),(97, 0.9489),(32, 0.0967),(176, 0.0353),(177, 0.1657),(36, 0.7068),(103, 0.4729)
              ) AS recommendations(car_id, rank_score)
              WHERE recommendations.car_id = cars.id
            )::float[])[1],
          NULL
        ) AS rank_score
        FROM cars
        INNER JOIN brands ON brands.id = cars.brand_id
        WHERE brands.name ILIKE '%Volkswagen%' AND cars.price > 10000 AND cars.price < 20000 ORDER BY
        CASE
          WHEN
          cars.brand_id IN (
            SELECT brand_id FROM user_preferred_brands WHERE user_id = :user_id
          )
          AND cars.price::INT8 <@ (SELECT preferred_price_range FROM users where id = :user_id) THEN 1
          WHEN cars.brand_id IN (SELECT brand_id FROM user_preferred_brands WHERE user_id = user_id) THEN 2
          ELSE 3
        END ASC,
        rank_score DESC NULLS LAST,
        price ASC
        LIMIT :limit
        OFFSET :offset
        ;
      SQL
    end

    it "renders sql with WHERE clause" do
      expect(build).to eq(expected_sql)
    end
  end

  context "with malformed ai_recommendations simulating sql injection" do
    let(:ai_recommendations) do
      [
        {"car_id" => "' OR 1=1; --", "rank_score" => 0.945}
      ]
    end

    it "raises type error" do
      expect { build }.to raise_error(ArgumentError)
    end
  end
end
