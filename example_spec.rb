require_relative 'spec_helper'

describe 'VCR', :vcr do
  it 'records a request' do
    Net::HTTP.get('google.com', '/')
  end
end
