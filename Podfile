# Uncomment the next line to define a global platform for your project
 platform :ios, '10.0'
use_frameworks!

target 'Exmoney' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
pod 'Floaty', :git => 'https://github.com/kciter/Floaty'
pod 'RealmSwift'
pod 'ReachabilitySwift'
pod 'DatePickerCell'
end

target 'ExmoneyTests' do
    
    pod 'Floaty', :git => 'https://github.com/kciter/Floaty'
    pod 'RealmSwift'
    pod 'ReachabilitySwift'
pod 'DatePickerCell'
end


post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '3.0'
        end
    end
end
