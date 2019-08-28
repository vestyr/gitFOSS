# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Gitlab::Favicon, :request_store do
  include RailsHelpers

  describe '.main' do
    it 'has green favicon for development' do
      stub_rails_env('development')
      expect(described_class.main).to match_asset_path 'favicon-green.png'
    end
  end
end
