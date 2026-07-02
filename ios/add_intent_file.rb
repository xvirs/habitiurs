#!/usr/bin/env ruby
# Agrega ToggleHabitIntent.swift al target del widget. Idempotente.
require 'xcodeproj'

project = Xcodeproj::Project.open(File.join(__dir__, 'Runner.xcodeproj'))
target = project.targets.find { |t| t.name == 'HabitiursWidgetExtension' }
abort 'No se encontró HabitiursWidgetExtension' unless target

file_name = 'ToggleHabitIntent.swift'

already = target.source_build_phase.files.any? do |bf|
  bf.file_ref&.display_name == file_name
end
if already
  puts "#{file_name} ya está en el target. Nada que hacer."
  exit 0
end

group = project.main_group.find_subpath('HabitiursWidget', true)
group.set_path('HabitiursWidget')
ref = group.files.find { |f| f.display_name == file_name } || group.new_reference(file_name)
target.add_file_references([ref])

project.save
puts "OK: #{file_name} agregado al target del widget."
