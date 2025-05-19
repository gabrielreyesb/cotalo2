namespace :setup do
  desc "Create default units"
  task create_default_units: :environment do
    default_units = [
      { name: 'Metro cuadrado', abbreviation: 'm²' },
      { name: 'Pieza', abbreviation: 'pcs' },
      { name: 'Pliego', abbreviation: 'set' },
      { name: 'Metro lineal', abbreviation: 'ml' },
      { name: 'Hora', abbreviation: 'hr' },
      { name: 'Proceso', abbreviation: 'proc' }
    ]

    default_units.each do |unit_attrs|
      Unit.find_or_create_by!(name: unit_attrs[:name], abbreviation: unit_attrs[:abbreviation])
    end

    puts "Default units created successfully!"
  end
end 