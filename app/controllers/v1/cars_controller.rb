module V1
  class CarsController < BaseController
    rescue_from ActionController::ParameterMissing, with: :missing_user_id
    rescue_from BravadoRecommendationClient::ApiError, with: :recommendation_error

    def index
      recommendations = RecommendationService.call(
        params.require(:user_id),
        params[:query],
        params[:price_min],
        params[:price_max],
        params.fetch(:page) { DEFAULT_PAGE }.to_i,
        params.fetch(:per_page) { DEFAULT_PAGE_SIZE }.to_i
      )

      render json: recommendations.to_json, status: :ok
    end

    private

    def missing_user_id
      render json: {error: "missing required user_id param"}, status: :unprocessable_entity
    end

    def recommendation_error(exception)
      render json: {error: exception.message}, status: :unprocessable_entity
    end
  end
end
