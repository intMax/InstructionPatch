#
# Be sure to run `pod lib lint InstructionPatch.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'InstructionPatch'
  s.version          = '0.0.1'
  s.summary          = 'InstructionPatch, iOS hotfix framework'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  This is an iOS hotfix framework that doesn't rely on any other language engine. It parses json files and uses the runtime to perform hot fixes. However, it also has many limitations.
                       DESC

  s.homepage         = 'https://github.com/intMax/InstructionPatch'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'intMax' => 'intmaxpan@163.com' }
  s.source           = { :git => 'https://github.com/intMax/InstructionPatch.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '7.0'

  s.source_files = 'InstructionPatch/Classes/**/*'
  
  # s.resource_bundles = {
  #   'InstructionPatch' => ['InstructionPatch/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
