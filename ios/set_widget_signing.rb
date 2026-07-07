#!/usr/bin/env ruby
# Pone la firma MANUAL en la config Release del target del widget, con su
# provisioning profile de App Store (para que el archive del CI lo firme bien).
require 'xcodeproj'

project = Xcodeproj::Project.open(File.join(__dir__, 'Runner.xcodeproj'))
target = project.targets.find { |t| t.name == 'HabitiursWidgetExtension' }
abort 'No se encontró HabitiursWidgetExtension' unless target

target.build_configurations.each do |config|
  next unless config.name == 'Release'
  s = config.build_settings
  s['CODE_SIGN_STYLE'] = 'Manual'
  s['CODE_SIGN_IDENTITY'] = 'Apple Distribution'
  s['PROVISIONING_PROFILE_SPECIFIER'] = 'Habitiurs Widget App Store'
  s['DEVELOPMENT_TEAM'] = 'SJVXS34P6P'
  puts "Release del widget → Manual + 'Habitiurs Widget App Store'."
end

project.save
puts 'OK.'
