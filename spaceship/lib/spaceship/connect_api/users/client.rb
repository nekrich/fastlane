require_relative '../api_client'
require_relative 'users'
require_relative '../../tunes/tunes_client'

module Spaceship
  class ConnectAPI
    module Users
      class Client < Spaceship::ConnectAPI::APIClient
        def initialize(cookie: nil, current_team_id: nil, token: nil, another_client: nil)
          another_client ||= Spaceship::Tunes.client if cookie.nil? && token.nil?

          super

          # Used by most iris requests starting in July 2021
          @additional_headers = { 'x-csrf-itc': '[asc-ui]' } if another_client

          self.extend(Spaceship::ConnectAPI::Users::API)
          self.users_request_client = self
        end

        def self.hostname
          'https://appstoreconnect.apple.com/iris/'
        end
      end
    end
  end
end
