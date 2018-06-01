#
# Be sure to run `pod lib lint Swux.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Swux'
  s.version          = '0.1.9'
  s.summary          = 'A Swiftier Redux'

  s.description      = <<-DESC
A Swifty implementation of the Redux JavaScript library's unidirectional data flow paradigm. Inspired by ReSwift, but with a Swiftier API involving action mutators, allowing for faster apps that take full advantage of Swift's copy-on-write and exclusive ownership features.
                       DESC

  s.homepage         = 'https://github.com/wircho/Swux'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'wircho' => 'correo.de.adolfo@gmail.com' }
  s.source           = { :git => 'https://github.com/wircho/Swux.git', :tag => s.version.to_s }

  s.swift_version = '4.1'

  s.ios.deployment_target = '10.0'
  s.osx.deployment_target = '10.13'

  s.source_files = 'Sources/Swux/*'
  
  s.frameworks = 'Foundation'
end
