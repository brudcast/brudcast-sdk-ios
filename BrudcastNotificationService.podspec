Pod::Spec.new do |s|
  s.name = 'BrudcastNotificationService'
  s.version = File.read(File.join(__dir__, 'Sources/Brudcast/Internal/BrudcastSDK.swift'))[/version = "([^"]+)"/, 1]
  s.summary = 'Notification service extension support for Brudcast push: rich media and delivery receipts.'
  s.homepage = 'https://github.com/brudcast/brudcast-sdk-ios'
  s.license = { type: 'Apache-2.0', file: 'LICENSE' }
  s.author = { 'Brudcast' => 'security@brudcast.com' }
  s.source = { git: 'https://github.com/brudcast/brudcast-sdk-ios.git', tag: "v#{s.version}" }

  s.ios.deployment_target = '14.0'
  s.swift_versions = ['5.9']

  s.source_files = 'Sources/BrudcastNotificationService/**/*.swift'
  s.resource_bundles = { 'BrudcastNotificationService_Privacy' => ['Sources/BrudcastNotificationService/PrivacyInfo.xcprivacy'] }
  s.frameworks = 'Foundation', 'UserNotifications'
end
