#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint chainway_rfid_scanner.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'chainway_rfid_scanner'
  s.version          = '0.1.0'
  s.summary          = 'Flutter integration for Chainway Bluetooth UHF RFID readers.'
  s.description      = <<-DESC
Connects Flutter applications to Chainway R2 Bluetooth UHF RFID readers.
                       DESC
  s.homepage         = 'https://github.com/amastsales/chainway_rfid_scanner'
  s.license          = { :file => '../LICENSE' }
  s.author           = 'AMAST Sales'
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*.{h,m}'
  s.public_header_files = 'Classes/ChainwayRfidScannerPlugin.h'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.frameworks = 'CoreBluetooth', 'ExternalAccessory'
  s.resource_bundles = {
    'chainway_rfid_scanner_privacy' => ['Resources/PrivacyInfo.xcprivacy']
  }

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }

end
