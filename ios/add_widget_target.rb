#!/usr/bin/env ruby
# Agrega el target del Widget Extension (HabitiursWidgetExtension) al proyecto.
# Idempotente: si ya existe, no hace nada.
require 'xcodeproj'

project_path = File.join(__dir__, 'Runner.xcodeproj')
project = Xcodeproj::Project.open(project_path)

if project.targets.any? { |t| t.name == 'HabitiursWidgetExtension' }
  puts 'El target HabitiursWidgetExtension ya existe. Nada que hacer.'
  exit 0
end

runner = project.targets.find { |t| t.name == 'Runner' }
abort 'No se encontró el target Runner' unless runner

widget = project.new_target(:app_extension, 'HabitiursWidgetExtension', :ios, '15.0')

# Grupo con los archivos del widget (carpeta HabitiursWidget).
group = project.main_group.find_subpath('HabitiursWidget', true)
group.set_path('HabitiursWidget')

%w[HabitData.swift HabitWidgets.swift HabitiursWidgetBundle.swift].each do |f|
  ref = group.new_reference(f)
  widget.add_file_references([ref])
end
group.new_reference('Info.plist')
group.new_reference('HabitiursWidget.entitlements')

widget.build_configurations.each do |config|
  s = config.build_settings
  s['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.habitiurs.app.HabitiursWidget'
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['INFOPLIST_FILE'] = 'HabitiursWidget/Info.plist'
  s['CODE_SIGN_ENTITLEMENTS'] = 'HabitiursWidget/HabitiursWidget.entitlements'
  s['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
  s['SWIFT_VERSION'] = '5.0'
  s['TARGETED_DEVICE_FAMILY'] = '1,2'
  s['MARKETING_VERSION'] = '1.0'
  s['CURRENT_PROJECT_VERSION'] = '1'
  s['GENERATE_INFOPLIST_FILE'] = 'NO'
  s['SKIP_INSTALL'] = 'YES'
  s['DEVELOPMENT_TEAM'] = 'SJVXS34P6P'
  s['CODE_SIGN_STYLE'] = 'Automatic'
  s['LD_RUNPATH_SEARCH_PATHS'] = [
    '$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks'
  ]
  s['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone' if config.name == 'Debug'
end

# Dependencia + embeber la extensión dentro de la app.
runner.add_dependency(widget)
embed = runner.new_copy_files_build_phase('Embed Foundation Extensions')
embed.symbol_dst_subfolder_spec = :plug_ins
ref = embed.add_file_reference(widget.product_reference, true)
ref.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

project.save
puts 'OK: target HabitiursWidgetExtension creado y embebido en Runner.'
