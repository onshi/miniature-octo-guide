class BravadoRecommendationClient
  ApiError = Class.new(StandardError)
  NotFoundError = Class.new(ApiError)
  UnavailableError = Class.new(ApiError) # TODO: maybe TimeoutError?

  API_BASE_URL = "https://bravado-images-production.s3.amazonaws.com/recomended_cars.json".freeze

  def initialize
  end

  def self.get_cars
  end

  private

  def get_cars
  end

  def connection
  end
end
