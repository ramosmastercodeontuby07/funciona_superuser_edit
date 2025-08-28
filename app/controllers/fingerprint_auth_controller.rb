# app/controllers/fingerprint_auth_controller.rb
class FingerprintAuthController < ApplicationController
    skip_forgery_protection
    def staff_login
      # mapear usuario Linux -> registro User de tu app
      linux_user = params[:linux_user] || "ramos"
      result = FingerprintClient.verify(user: linux_user)
      if result["ok"]
        user = User.find_by!(username: linux_user) # ajusta el mapeo
        session[:user_id] = user.id
        render json: { ok: true }
      else
        render json: { ok: false }, status: :unauthorized
      end
    end
  end
  