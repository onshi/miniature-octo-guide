module RecommendationService
  extend self

  CACHE_TTL = 24.hours.freeze
  CACHE_CAR_RECOMMENDATION_KEY = "recommended_cars".freeze

  def call(user_id, query, price_min, price_max, page, per_page)
    recommended_cars = Rails.cache.fetch("#{CACHE_CAR_RECOMMENDATION_KEY}-#{user_id}", expires_in: CACHE_TTL) do
      fetch_recommended_cars_from_api(user_id)
    end

    sql = ActiveRecord::Base.sanitize_sql_array(
      [
        RecommendationsQuery.build(recommended_cars, query, price_min, price_max),
        {
          user_id: user_id,
          limit: per_page,
          offset: (page - 1) * per_page
        }
      ]
    )
    results = ActiveRecord::Base.connection.execute(sql)
    results.map do |result|
      {
        id: result["id"],
        brand: {
          id: result["brand_id"],
          name: result["brand_name"]
        },
        model: result["model"],
        price: result["price"],
        rank_score: result["rank_score"],
        label: result["label"]
      }
    end
  end

  private

  def fetch_recommended_cars_from_api(user_id)
    BravadoRecommendationClient.get_cars(user_id)
  end
end
