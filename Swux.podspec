#
# Be sure to run `pod lib lint Swux.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Swux'
  s.version          = '0.1.0'
  s.summary          = 'A short description of Swux.'

  s.description      = <<-DESC
A Swift-ier implementation of Redux.
                       DESC

  s.homepage         = 'https://github.com/wircho/Swux'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'wircho' => 'correo.de.adolfo@gmail.com' }
  s.source           = { :git => 'https://github.com/wircho/Swux.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'Swux/*'
  
  s.frameworks = 'Foundation'
end
