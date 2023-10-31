# Uncomment the next line to define a global platform for your project
 platform :ios, '12.0'

target 'AlamofireDemo' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for AlamofireDemo
pod 'Alamofire', '~> 4.0'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        xcconfig_path = config.base_configuration_reference.real_path
        xcconfig = File.read(xcconfig_path)
        xcconfig_mod = xcconfig.gsub(/DT_TOOLCHAIN_DIR/, "TOOLCHAIN_DIR")
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
        File.open(xcconfig_path, "w") { |file| file << xcconfig_mod }
      end
  end
end
