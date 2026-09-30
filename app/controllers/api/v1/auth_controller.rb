module Api
  module V1
    class AuthController < ApplicationController
      wrap_parameters false
      allow_unauthenticated_access only: %i[signup login refresh logout]
      rate_limit to: 10, within: 3.minutes, only: %i[signup login refresh],
        with: -> { render json: { error: "rate_limited" }, status: :too_many_requests }

      def signup
        user = User.new(name: params[:name], email: params[:email], password: params[:password])
        if user.save
          render json: token_pair_for(user), status: :created
        else
          render json: { error: "validation_failed", details: user.errors.to_hash(true) }, status: :unprocessable_content
        end
      end

      def login
        user = User.authenticate_by(email: params[:email].to_s, password: params[:password].to_s)
        if user
          render json: token_pair_for(user)
        else
          render json: { error: "invalid_credentials" }, status: :unauthorized
        end
      end

      def refresh
        record = RefreshToken.find_by_raw(params[:refresh_token])
        return render_unauthorized("invalid_refresh_token") unless record

        record.with_lock do
          if record.revoked_at
            # A rotated token was replayed; assume it leaked and end every session.
            record.user.refresh_tokens.active.update_all(revoked_at: Time.current)
            return render_unauthorized("invalid_refresh_token")
          end
          return render_unauthorized("invalid_refresh_token") unless record.active?

          record.revoke!
        end
        render json: token_pair_for(record.user)
      end

      def logout
        RefreshToken.find_by_raw(params[:refresh_token])&.revoke!
        head :no_content
      end

      def me
        render json: { user: user_json(current_user) }
      end

      private
        def token_pair_for(user)
          _record, refresh_token = RefreshToken.issue_for(user)
          {
            access_token: JsonWebToken.encode(user),
            token_type: "Bearer",
            expires_in: JsonWebToken::TTL.to_i,
            refresh_token: refresh_token,
            user: user_json(user)
          }
        end

        def user_json(user)
          { id: user.id, name: user.name, email: user.email }
        end
    end
  end
end
