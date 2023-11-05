# frozen_string_literal: true

helpers do
  def json_response(payload, status_code)
    status status_code
    payload.to_json
  end
end