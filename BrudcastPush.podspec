Pod::Spec.new do |s|
  s.name = 'BrudcastPush'
  s.version = File.read(File.join(__dir__, 'Sources/Brudcast/Internal/BrudcastSDK.swift'))[/version = "([^"]+)"/, 1]
  s.summary = 'Push notifications for Brudcast: permission, token registration, display, and open and dismiss tracking.'
  s.homepage = 'https://github.com/brudcast/brudcast-sdk-ios'
  s.license = { type: 'Apache-2.0', file: 'LICENSE' }
  s.author = { 'Brudcast' => 'security@brudcast.com' }
  s.source = { git: 'https://github.com/brudcast/brudcast-sdk-ios.git', tag: "v#{s.version}" }

  s.ios.deployment_target = '14.0'
  s.swift_versions = ['5.9']

  s.source_files = 'Sources/BrudcastPush/**/*.swift'
  s.resource_bundles = { 'BrudcastPush_Privacy' => ['Sources/BrudcastPush/PrivacyInfo.xcprivacy'] }
  s.frameworks = 'Foundation', 'UIKit', 'UserNotifications'

  s.dependency 'Brudcast', s.version.to_s
  s.dependency 'BrudcastNotificationService', s.version.to_s
end
