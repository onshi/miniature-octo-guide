module RecommendationsQuery
  extend self

  def build(recommendations_scores, brand_name = nil, price_min = nil, price_max = nil)
    sql = <<-SQL.gsub(/^\s+/, "")
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
              VALUES #{convert_ai_recommendations_to_values(recommendations_scores)}
            ) AS recommendations(car_id, rank_score)
            WHERE recommendations.car_id = cars.id
          )::float[])[1],
        NULL
      ) AS rank_score
      FROM cars
      INNER JOIN brands ON brands.id = cars.brand_id
    SQL

    filters = create_filters(brand_name, price_min, price_max)

    sql += "WHERE #{filters.join(" AND ")} " if !filters.empty?

    sql + <<-SQL.gsub(/^\s+/, "")
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

  private

  def convert_ai_recommendations_to_values(ai_recommendations)
    ai_recommendations.map do |score|
      "(#{Integer(score["car_id"])}, #{Float(score["rank_score"])})"
    end.join(",")
  end

  def create_filters(brand_name, price_min, price_max)
    [].tap do |filters|
      filters.push("brands.name ILIKE '%#{brand_name}%'") if brand_name.presence
      filters.push("cars.price > #{price_min}") if price_min.presence
      filters.push("cars.price < #{price_max}") if price_max.presence
    end
  end
end
