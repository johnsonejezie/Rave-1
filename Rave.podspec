Pod::Spec.new do |s|

# 1
s.platform = :ios
s.ios.deployment_target = '8.0'
s.name = "Rave"
s.summary = "Rave iOS SDK"
s.requires_arc = true

# 2
s.version = "0.1.0"

# 3
s.license = { :type => "MIT", :file => "LICENSE" }

# 4 - Replace with your name and e-mail address
s.author = { "Segun Solaja" => "segun.solaja@gmail.com" }



# 5 - Replace this URL with your own Github page's URL (from the address bar)
s.homepage = "https://ravepay.co/"




# 6 - Replace this URL with your own Git URL from "Quick Setup"
s.source = { :git => "https://github.com/solejay/Rave-iOS.git", :tag => "#{s.version}"}

# For example,
# s.source = { :git => "https://github.com/JRG-Developer/RWPickFlavor.git", :tag => "#{s.version}"}

s.pod_target_xcconfig = { 'SWIFT_VERSION' => '3.0' }

# 7
s.framework = 'UIKit'
s.dependency 'Alamofire'
#s.dependency 'BSErrorMessageView'
s.dependency 'IQKeyboardManagerSwift','~> 4.0.6'
s.dependency 'SwiftValidator'
s.dependency 'KVNProgress', '~> 2.3.1'
s.dependency 'PopupDialog', '~> 0.5.4'
s.dependency 'Shimmer', '~> 1.0.2'


# 8
s.source_files = "Rave/**/*.{swift}"

# 9
s.resources = "Rave/**/*.{png,jpeg,jpg,pdf,storyboard,xib}"
end
