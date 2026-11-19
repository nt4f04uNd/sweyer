#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint sweyer_plugin.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'sweyer_plugin'
  s.version          = '0.0.1'
  s.summary          = 'Plugin for native components of Sweyer.'
  s.description      = <<-DESC
Plugin for native components of Sweyer.
                       DESC
  s.homepage         = 'https://github.com/nt4f04uNd/sweyer'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'nt4f04und' => 'nt4f04und@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '11.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
