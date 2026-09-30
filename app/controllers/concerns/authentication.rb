module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate!
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :authenticate!, **options
    end
  end

  private
    attr_reader :current_user

    def authenticate!
      token = request.authorization.to_s[/\ABearer (.+)\z/, 1]
      payload = JsonWebToken.decode(token.to_s)
      @current_user = User.find_by(id: payload["user_id"])
      render_unauthorized("invalid_token") unless @current_user
    rescue JsonWebToken::InvalidToken
      render_unauthorized("invalid_token")
    end

    def render_unauthorized(error)
      response.set_header("WWW-Authenticate", %(Bearer error="#{error}"))
      render json: { error: error }, status: :unauthorized
    end
end
