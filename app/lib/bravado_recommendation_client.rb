class BravadoRecommendationClient
  ApiError = Class.new(StandardError)
  UnavailableError = Class.new(ApiError) # TODO: maybe TimeoutError?

  API_BASE_URL = "https://bravado-images-production.s3.amazonaws.com/recomended_cars.json".freeze
  CLIENT_OPTIONS = {
    request: {
      open_timeout: 5,
      timeout: 5
    },
    url: API_BASE_URL,
    headers: {
      "Content-Type" => "application/json"
    }
  }.freeze

  class << self
    def get_cars(user_id)
      client.get(API_BASE_URL, {user_id: user_id}).body
    rescue Faraday::ParsingError => e
      raise ApiError.new(e)
    rescue Faraday::ConnectionFailed, Faraday::RequestTimeoutError => e
      raise UnavailableError.new(e)
    end

    private

    def client
      @client ||= Faraday.new do |builder|
        builder.use(
          :http_cache,
          store: Rails.cache,
          logger: Rails.logger,
          strategy: Faraday::HttpCache::Strategies::ByVary
        )

        builder.adapter Faraday.default_adapter

        builder.response :json
      end
    end
  end
end
