# frozen_string_literal: true

module Routes
  # Routes::Application
  class Application < ::Roda
    opts[:root] = ENV.fetch('APP_ROOT', nil)
    plugin :all_verbs
    plugin :symbol_status
    plugin :json, content_type: 'application/vnd.api+json'
    plugin :json_parser
    plugin :slash_path_empty
    plugin :hash_routes
    plugin :request_headers

    route do |req|
      req.on('licenses') do
        req.is('verify', method: :post) do
          uuid = req.params['uuid']
          passport_no = req.params['passport_no']
          license_data = Utils::RedisStorage.get(uuid)

          unless license_data.is_a?(Hash)
            valid = FFaker::Boolean.maybe
            past_dates1 = [(::Date.today - 30), (::Date.today - 1)]
            past_dates2 = [(::Date.today - 60), (::Date.today - 31)]
            future_dates1 = [(::Date.today + 1), (::Date.today + 30)]

            license_data = {
             valid:       valid,
             passport_no: passport_no,
             start_date:  (valid ? FFaker::Date.between(*past_dates1) : FFaker::Date.between(*past_dates2)).iso8601,
             end_date:    (valid ? FFaker::Date.between(*future_dates1) : FFaker::Date.between(*past_dates1)).iso8601,
            }

            Utils::RedisStorage.set(uuid, license_data)
          end

          response.status = 200
          license_data
        end
      end
    end
  end
end
