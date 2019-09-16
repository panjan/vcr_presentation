require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.default_cassette_options = { :record => :new_episodes }
end

describe "VCR", :vcr do
  it 'records an http request' do
    5.times do
      puts Net::HTTP.get_response('localhost', '/', 4567).body
    end
  end
end
