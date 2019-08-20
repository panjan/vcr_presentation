require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
end

describe "VCR", :vcr do
  it 'records an http request' do
    10.times do
      Net::HTTP.get_response('localhost', '/', 4567)
    end
  end
end
