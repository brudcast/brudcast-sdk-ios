Pod::Spec.new do |s|
  s.name = 'Brudcast'
  s.version = File.read(File.join(__dir__, 'Sources/Brudcast/Internal/BrudcastSDK.swift'))[/version = "([^"]+)"/, 1]
  s.summary = 'Core of the Brudcast SDK: configuration, device id, sessions, identity, events and the action handler.'
  s.homepage = 'https://github.com/brudcast/brudcast-sdk-ios'
  s.license = { type: 'Apache-2.0', file: 'LICENSE' }
  s.author = { 'Brudcast' => 'security@brudcast.com' }
  s.source = { git: 'https://github.com/brudcast/brudcast-sdk-ios.git', tag: "v#{s.version}" }

  s.ios.deployment_target = '14.0'
  s.swift_versions = ['5.9']

  s.source_files = 'Sources/Brudcast/**/*.swift'
  s.resource_bundles = { 'Brudcast_Privacy' => ['Sources/Brudcast/PrivacyInfo.xcprivacy'] }
  s.frameworks = 'Foundation', 'UIKit', 'Security', 'CryptoKit'
end
