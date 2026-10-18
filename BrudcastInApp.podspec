Pod::Spec.new do |s|
  s.name = 'BrudcastInApp'
  s.version = File.read(File.join(__dir__, 'Sources/Brudcast/Internal/BrudcastSDK.swift'))[/version = "([^"]+)"/, 1]
  s.summary = 'In-app messages for Brudcast: sync, the live stream, triggers, display rules, SwiftUI rendering and the inbox.'
  s.homepage = 'https://github.com/brudcast/brudcast-sdk-ios'
  s.license = { type: 'Apache-2.0', file: 'LICENSE' }
  s.author = { 'Brudcast' => 'security@brudcast.com' }
  s.source = { git: 'https://github.com/brudcast/brudcast-sdk-ios.git', tag: "v#{s.version}" }

  s.ios.deployment_target = '14.0'
  s.swift_versions = ['5.9']

  s.source_files = 'Sources/BrudcastInApp/**/*.swift'
  s.resource_bundles = { 'BrudcastInApp_Privacy' => ['Sources/BrudcastInApp/PrivacyInfo.xcprivacy'] }
  s.frameworks = 'Foundation', 'UIKit', 'SwiftUI', 'Combine', 'SafariServices'

  s.dependency 'Brudcast', s.version.to_s
end
