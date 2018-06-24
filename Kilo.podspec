Pod::Spec.new do |s|
  s.name            = 'Kilo'
  s.version         = 1.0'
  s.license         = 'Apache License, Version 2.0'
  s.homepage        = 'https://github.com/gk-brown/Kilo'
  s.author          = 'Greg Brown'
  s.summary         = 'Lightweight REST client for iOS and tvOS'
  s.source          = { :git => "https://github.com/gk-brown/Kilo.git", :tag => s.version.to_s }

  s.ios.deployment_target   = '10.0'
  s.ios.source_files        = 'Kilo-iOS/Kilo/*.{h,m}'
  s.tvos.deployment_target  = '10.0'
  s.tvos.source_files       = 'Kilo-iOS/Kilo/*.{h,m}'
end
