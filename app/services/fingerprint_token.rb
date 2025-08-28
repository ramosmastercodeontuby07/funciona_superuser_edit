# app/services/fingerprint_client.rb
require "net/http"
require "json"
require "uri"
require "cgi"

class FingerprintClient
  FINGERBRIDGE_URL = ENV.fetch("FINGERBRIDGE_URL", "http://127.0.0.1:8787")

  def self.verify(user:)
    uri = URI.parse("#{FINGERBRIDGE_URL}/verify?user=#{CGI.escape(user)}")
    res = Net::HTTP.get_response(uri)
    if res.is_a?(Net::HTTPSuccess)
      JSON.parse(res.body) rescue { "ok" => true }
    else
      body = begin JSON.parse(res.body) rescue {} end
      { "ok" => false, "error" => body["detail"] || body["error"] || "#{res.code} #{res.message}" }
    end
  rescue => e
    { "ok" => false, "error" => e.message }
  end
end
