# Script to update existing manufacturing processes with units

# Find the user by email
user = User.find_by(email: 'gabrielreyesb@gmail.com')

unless user
  puts "Error: User with email gabrielreyesb@gmail.com not found"
  exit
end

puts "Updating manufacturing processes for user: #{user.email}"

# Create or find necessary units
hour_unit = user.units.find_by(name: 'Hour')
if !hour_unit
  hour_unit = user.units.create!(name: 'Hour', abbreviation: 'hr')
  puts "Created new unit: Hour (hr)"
end

sq_meter_unit = user.units.find_by(abbreviation: 'm²')
pieces_unit = user.units.find_by(abbreviation: 'pcs')
process_unit = user.units.find_by(abbreviation: 'bag')

# List all units for debugging
puts "Available units:"
user.units.each do |unit|
  puts "- #{unit.name} (#{unit.abbreviation})"
end

# Process mappings based on actual process names
unit_mappings = {
  'Plastificado' => sq_meter_unit,
  'Empalmado' => process_unit,
  'Impresión 3 colores' => sq_meter_unit
}

# Update processes
updated_count = 0
user.manufacturing_processes.each do |process|
  puts "Checking process: #{process.name}"
  if unit_mappings.key?(process.name)
    process.unit = unit_mappings[process.name]
    if process.save
      updated_count += 1
      puts "  Updated with unit: #{process.unit.name}"
    else
      puts "  Failed to update: #{process.errors.full_messages.join(', ')}"
    end
  else
    # Default to hour unit if no specific mapping
    process.unit = hour_unit
    if process.save
      updated_count += 1
      puts "  Updated with default unit (Hour)"
    else
      puts "  Failed to update with default unit: #{process.errors.full_messages.join(', ')}"
    end
  end
end

puts "Updated #{updated_count} manufacturing processes with appropriate units" 