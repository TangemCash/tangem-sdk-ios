#
# Be sure to run `pod lib lint TangemSdk.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'TangemSdk'
  s.version          = '3.7.0'
  s.summary          = 'Use TangemSdk for Tangem cards integration'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Tangem is a Swiss-based secure hardware wallet manufacturer that enables blockchain-based assets to be kept in custody within smart physical banknotes and accessed via NFC technology. Tangem’s mission is to make digital assets accessible, affordable and convenient for consumers.
                       DESC

  s.homepage         = 'https://github.com/Tangem/tangem-sdk-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Tangem' => 'hello@tangem.com' }
  s.source           = { :git => 'https://github.com/Tangem/tangem-sdk-ios.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/Tangem'
  s.platform = :ios
  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  s.source_files = 'TangemSdk/TangemSdk/**/*.{swift}', 
		   'TangemSdk/TangemSdk/TangemSdk.h',
   		   'TangemSdk/TangemSdk/Crypto/secp256k1/src/*.{h,c}',
	           'TangemSdk/TangemSdk/Crypto/secp256k1/src/include/*.{h,c}',
  		   'TangemSdk/TangemSdk/Crypto/secp256k1/src/modules/{recovery,ecdh}/*.{h,c}'

  s.exclude_files = 'TangemSdk/TangemSdk/Crypto/secp256k1/src/*test*.{c,h}', 
		    'TangemSdk/TangemSdk/Crypto/secp256k1/src/gen_context.c', 
		    'TangemSdk/TangemSdk/Crypto/secp256k1/src/*bench*.{c,h}', 
                    'TangemSdk/TangemSdk/Crypto/secp256k1/contrib/*',
		    'TangemSdk/TangemSdk/Crypto/secp256k1/src/modules/{recovery,ecdh}/*test*.{c,h}'

 
  s.preserve_path = 'TangemSdk/TangemSdk/module.modulemap'
  s.public_header_files = 'TangemSdk/TangemSdk/TangemSdk.h'
  s.pod_target_xcconfig = {
    'SWIFT_INCLUDE_PATHS' => '$(PODS_TARGET_SRCROOT)/TangemSdk/**',
    'OTHER_CFLAGS' => '-pedantic -Wall -Wextra -Wcast-align -Wnested-externs -Wshadow -Wstrict-prototypes -Wno-shorten-64-to-32 -Wno-conditional-uninitialized -Wno-unused-function -Wno-long-long -Wno-overlength-strings -O3',
  }

  s.weak_frameworks = 'CoreNFC', 'CryptoKit', 'Combine', 'SwiftUI'

  s.resource_bundles = { 'TangemSdk' => ['TangemSdk/TangemSdk/**/*.lproj/*.strings', 
					'TangemSdk/TangemSdk/Haptics/*.ahap',
					'TangemSdk/TangemSdk/**/Wordlists/*.txt']}

end
