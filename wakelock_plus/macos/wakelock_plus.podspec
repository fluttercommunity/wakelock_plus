#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint wakelock_plus.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'wakelock_plus'
  s.version          = '0.0.1'
  s.summary          = 'Plugin that allows you to keep the device screen awake, i.e. prevent the screen from sleeping on Android, iOS, macOS, Windows, and web.'
  s.description      = <<-DESC
  Plugin that allows you to keep the device screen awake, i.e. prevent the screen from sleeping on Android, iOS, macOS, Windows, and web.
                       DESC
  s.homepage         = 'https://github.com/fluttercommunity/wakelock_plus'
  s.license          = { :type => 'BSD', :file => '../LICENSE' }
  s.author           = { 'Flutter Team' => 'flutter-dev@googlegroups.com' }
  s.source           = { :http => 'https://github.com/fluttercommunity/wakelock_plus/tree/main/packages/wakelock_plus_macos' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
