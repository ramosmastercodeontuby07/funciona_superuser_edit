# app/controllers/api/fp/fingerprints_controller.rb
module Api
  module Fp
    class FingerprintsController < ApplicationController
      require "net/http"
      require "json"

      # Este endpoint se usa vía fetch (JSON)
      skip_before_action :verify_authenticity_token, only: [:verify]

      # POST /api/fp/verify  { linux_user: "ramos" }
      # Llama a fingerbridge (http://127.0.0.1:5005/verify) que a su vez llama a fprintd.
      def verify
        linux_user = params[:linux_user].to_s.strip
        return render json: { ok: false, error: "linux_user requerido" }, status: :bad_request if linux_user.blank?

        uri = URI("http://127.0.0.1:5005/verify")
        req = Net::HTTP::Post.new(uri)
        req["Content-Type"] = "application/json"
        req["X-Secret"]      = ENV.fetch("FINGERBRIDGE_SECRET")
        req.body = { username: linux_user }.to_json

        res  = Net::HTTP.start(uri.hostname, uri.port, read_timeout: 25) { |h| h.request(req) }
        body = JSON.parse(res.body) rescue {}

        if res.code.to_i == 200
          render json: { ok: true, match: !!body["match"], raw: body["raw"] }
        else
          render json: { ok: false, error: body["error"] || "fingerbridge-error" }, status: :bad_gateway
        end
      rescue => e
        render json: { ok: false, error: e.message }, status: :internal_server_error
      end
    end
  end
end
