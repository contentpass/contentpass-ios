Pod::Spec.new do |spec|
  spec.name         = "ContentPass"
  spec.version      = "2.1.0"
  spec.summary      = "Handles all authentication and validation with contentpass servers for you."

  spec.homepage     = "https://contentpass.de"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author             = "Content Pass GmbH" 
  
  spec.platform     = :ios
  spec.ios.deployment_target = "10.0"

  spec.source       = { :git => "https://github.com/contentpass/contentpass-ios.git", :tag => "#{spec.version}" }
  spec.source_files  = "Sources/**/*"

  spec.dependency 'AppAuth', '1.7.5'
  spec.dependency 'Strongbox', '0.6.1'
end
