Pod::Spec.new do |s|

# 1
s.platform = :ios
s.ios.deployment_target = '12.0'
s.name = "DiHolaShakingAPI"
s.summary = "DiHolaShakingAPI ..."
s.requires_arc = true

# 2
s.version = "0.1.5"

# 3
s.license = { :type => "Apache 2.0", :file => "LICENSE" }

# 4 - Replace with your name and e-mail address
s.author = { "Juanse Brito" => "juan.brito@diholapp.com" }

# 5 - Replace this URL with your own GitHub page's URL (from the address bar)
s.homepage = "https://github.com/diholapp/shaking-api-ios"

# 6 - Replace this URL with your own Git URL from "Quick Setup"
s.source = { :git => "https://github.com/diholapp/shaking-api-ios.git",
:tag => "#{s.version}" }

# 7
s.framework = "UIKit"

# 8
s.source_files = "DiHolaShakingAPI/**/*.{swift}"

# 9
#s.resources = "DiHolaShakingAPI/**/*.{png,jpeg,jpg,storyboard,xib,xcassets}"

# 10
s.swift_version = "4.2"

end
