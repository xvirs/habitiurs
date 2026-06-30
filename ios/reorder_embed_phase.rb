#!/usr/bin/env ruby
# Mueve la fase "Embed Foundation Extensions" del target Runner para que corra
# ANTES de "Thin Binary" / "[CP] Embed Pods Frameworks" y se rompa el ciclo.
require 'xcodeproj'

project = Xcodeproj::Project.open(File.join(__dir__, 'Runner.xcodeproj'))
runner = project.targets.find { |t| t.name == 'Runner' }
abort 'No Runner' unless runner

phases = runner.build_phases
embed = phases.find { |p| p.display_name == 'Embed Foundation Extensions' }
abort 'No embed phase' unless embed

# Índice de la primera fase de las que generan el ciclo (las que tocan el bundle).
cycle_names = ['Thin Binary', '[CP] Embed Pods Frameworks', '[CP] Copy Pods Resources']
target_idx = phases.index { |p| cycle_names.include?(p.display_name) }

if target_idx.nil?
  puts 'No se encontraron fases del ciclo; nada que reordenar.'
  exit 0
end

phases.delete(embed)
# recalcular el índice tras borrar (embed estaba después, así que no afecta target_idx)
phases.insert(target_idx, embed)

project.save
puts "Reordenado: 'Embed Foundation Extensions' ahora antes de '#{phases[target_idx + 1].display_name}'."
