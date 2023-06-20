#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint wakelock_plus.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'wakelock_plus'
  s.version          = '0.0.1'
  s.summary          = 'No-op implementation of the macos wakelock_plus plugin to avoid build issues on macos'
  s.description      = <<-DESC
  No-op implementation of the wakelock_plus plugin to avoid build issues on macos.
  https://github.com/flutter/flutter/issues/46618
                       DESC
  s.homepage         = 'https://github.com/fluttercommunity/wakelock_plus'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Flutter Team' => 'flutter-dev@googlegroups.com' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
