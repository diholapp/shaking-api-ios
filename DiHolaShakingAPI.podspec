Pod::Spec.new do |s|

s.platform = :ios
s.ios.deployment_target = '10.0'
s.name = "DiHolaShakingAPI"
s.summary = "Build fast and reliable ways to communicate between devices, just by shaking them."
s.requires_arc = true

s.version = "0.5.5"

s.license = { :type => "Apache 2.0", :file => "LICENSE" }

s.author = { "Juanse Brito" => "juan.brito@diholapp.com" }

s.homepage = "https://github.com/diholapp/shaking-api-ios"

s.source = { :git => "https://github.com/diholapp/shaking-api-ios.git", :tag => "#{s.version}" }

s.framework = "UIKit"

s.source_files = "DiHolaShakingAPI/**/*.{swift}"

s.swift_version = "4.2"

end
