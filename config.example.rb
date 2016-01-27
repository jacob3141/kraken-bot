KrakenClient.configure do |config|
      config.api_key     = '[API KEY]'
      config.api_secret  = '[API SECRET]'
      config.base_uri    = 'https://api.kraken.com'
      config.api_version = 0
      config.limiter     = true
      config.tier        = 3 # Adjust your tier here
end
