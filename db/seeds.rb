# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Clear existing data to prevent duplicates
puts "Clearing existing data..."
Material.destroy_all
Unit.destroy_all
User.where(email: 'admin@example.com').destroy_all

# Create default admin user
admin = User.create!(
  email: 'admin@example.com',
  password: 'password123',
  password_confirmation: 'password123'
)

# Create common units
puts "Creating units..."
units = [
  { name: 'Meter', abbreviation: 'm' },
  { name: 'Centimeter', abbreviation: 'cm' },
  { name: 'Millimeter', abbreviation: 'mm' },
  { name: 'Kilogram', abbreviation: 'kg' },
  { name: 'Gram', abbreviation: 'g' },
  { name: 'Square Meter', abbreviation: 'm²' },
  { name: 'Piece', abbreviation: 'pcs' },
  { name: 'Linear Meter', abbreviation: 'lm' },
  { name: 'Set', abbreviation: 'set' },
  { name: 'Bag', abbreviation: 'bag' },
  { name: 'Roll', abbreviation: 'roll' },
  { name: 'Box', abbreviation: 'box' },
  { name: 'Cubic Meter', abbreviation: 'm³' },
  { name: 'Liter', abbreviation: 'l' },
  { name: 'Sheet', abbreviation: 'sht' },
  { name: 'Pair', abbreviation: 'pr' },
  { name: 'Pack', abbreviation: 'pk' }
]

created_units = {}
units.each do |unit_attrs|
  unit = admin.units.create!(unit_attrs)
  created_units[unit_attrs[:abbreviation]] = unit
end

# Create materials by category
puts "Creating materials..."

# Construction materials
construction_materials = [
  { 
    description: 'Portland Cement', 
    nombre: 'Cemento Portland',
    price: 120.00, 
    unit: created_units['bag'], 
    especificaciones: '50kg bag, Type I',
    comments: 'General purpose cement'
  },
  { 
    description: 'Sand', 
    nombre: 'Arena',
    price: 450.00, 
    unit: created_units['m³'], 
    especificaciones: 'Fine grain, washed',
    comments: 'For concrete and mortar'
  },
  { 
    description: 'Gravel', 
    nombre: 'Grava',
    price: 500.00, 
    unit: created_units['m³'], 
    especificaciones: '3/4" size',
    comments: 'For concrete mixing'
  },
  { 
    description: 'Concrete Block', 
    nombre: 'Bloque de Concreto',
    price: 12.50, 
    unit: created_units['pcs'], 
    ancho: 20.0, 
    largo: 40.0,
    especificaciones: '20x20x40cm, hollow',
    comments: 'Standard concrete block'
  },
  { 
    description: 'Rebar', 
    nombre: 'Varilla',
    price: 95.00, 
    unit: created_units['pcs'], 
    largo: 12.0,
    especificaciones: '3/8" diameter, 12m length',
    comments: 'Steel reinforcement bar'
  }
]

# Metal materials
metal_materials = [
  { 
    description: 'Aluminum Sheet', 
    nombre: 'Lámina de Aluminio',
    price: 350.00, 
    unit: created_units['m²'], 
    ancho: 120.0, 
    largo: 240.0,
    especificaciones: '1mm thickness',
    comments: 'Lightweight and corrosion resistant'
  },
  { 
    description: 'Stainless Steel Sheet', 
    nombre: 'Lámina de Acero Inoxidable',
    price: 580.00, 
    unit: created_units['m²'], 
    ancho: 120.0, 
    largo: 240.0,
    especificaciones: '1.5mm thickness, Grade 304',
    comments: 'Durable and corrosion resistant'
  },
  { 
    description: 'Steel Tube', 
    nombre: 'Tubo de Acero',
    price: 125.00, 
    unit: created_units['pcs'], 
    largo: 6.0,
    especificaciones: '2" diameter, 6m length',
    comments: 'For structural frameworks'
  },
  { 
    description: 'Aluminum Angle', 
    nombre: 'Ángulo de Aluminio',
    price: 85.00, 
    unit: created_units['pcs'], 
    largo: 6.0,
    especificaciones: '1"x1", 6m length',
    comments: 'For framing and edging'
  },
  { 
    description: 'Galvanized Sheet', 
    nombre: 'Lámina Galvanizada',
    price: 320.00, 
    unit: created_units['m²'], 
    ancho: 120.0, 
    largo: 240.0,
    especificaciones: '0.7mm thickness',
    comments: 'Rust resistant'
  }
]

# Wood materials
wood_materials = [
  { 
    description: 'Plywood', 
    nombre: 'Triplay',
    price: 420.00, 
    unit: created_units['sht'], 
    ancho: 122.0, 
    largo: 244.0,
    especificaciones: '18mm thickness, marine grade',
    comments: 'Water resistant'
  },
  { 
    description: 'Pine Lumber', 
    nombre: 'Madera de Pino',
    price: 85.00, 
    unit: created_units['pcs'], 
    ancho: 10.0, 
    largo: 250.0,
    especificaciones: '2x4" profile, 2.5m length',
    comments: 'For general construction'
  },
  { 
    description: 'MDF Board', 
    nombre: 'Tablero MDF',
    price: 350.00, 
    unit: created_units['sht'], 
    ancho: 122.0, 
    largo: 244.0,
    especificaciones: '12mm thickness',
    comments: 'For furniture and interior work'
  },
  { 
    description: 'Hardwood Flooring', 
    nombre: 'Piso de Madera Dura',
    price: 650.00, 
    unit: created_units['m²'], 
    especificaciones: 'Oak, 14mm thickness',
    comments: 'Pre-finished'
  }
]

# Glass and plastic materials
glass_plastic_materials = [
  { 
    description: 'Tempered Glass', 
    nombre: 'Vidrio Templado',
    price: 850.00, 
    unit: created_units['m²'], 
    especificaciones: '10mm thickness, clear',
    comments: 'Safety glass for doors and partitions'
  },
  { 
    description: 'Acrylic Sheet', 
    nombre: 'Lámina Acrílica',
    price: 480.00, 
    unit: created_units['m²'], 
    ancho: 120.0, 
    largo: 240.0,
    especificaciones: '5mm thickness, clear',
    comments: 'For displays and signage'
  },
  { 
    description: 'PVC Pipe', 
    nombre: 'Tubo PVC',
    price: 45.00, 
    unit: created_units['pcs'], 
    largo: 6.0,
    especificaciones: '2" diameter, 6m length',
    comments: 'For plumbing and drainage'
  },
  { 
    description: 'Polycarbonate Sheet', 
    nombre: 'Lámina de Policarbonato',
    price: 580.00, 
    unit: created_units['m²'], 
    ancho: 120.0, 
    largo: 240.0,
    especificaciones: '6mm thickness, clear',
    comments: 'Impact resistant'
  }
]

# Finishing materials
finishing_materials = [
  { 
    description: 'Ceramic Tile', 
    nombre: 'Azulejo Cerámico',
    price: 280.00, 
    unit: created_units['m²'], 
    especificaciones: '30x30cm, white gloss',
    comments: 'For floors and walls'
  },
  { 
    description: 'Paint', 
    nombre: 'Pintura',
    price: 450.00, 
    unit: created_units['l'], 
    especificaciones: 'Acrylic, white matte',
    comments: 'Interior/exterior paint, 20L bucket'
  },
  { 
    description: 'Laminate Flooring', 
    nombre: 'Piso Laminado',
    price: 280.00, 
    unit: created_units['m²'], 
    especificaciones: '8mm thickness, wood effect',
    comments: 'Easy to install'
  },
  { 
    description: 'Drywall Sheet', 
    nombre: 'Panel de Yeso',
    price: 165.00, 
    unit: created_units['sht'], 
    ancho: 120.0, 
    largo: 240.0,
    especificaciones: '12.7mm thickness',
    comments: 'For walls and ceilings'
  }
]

# Hardware and fasteners
hardware_materials = [
  { 
    description: 'Wood Screws', 
    nombre: 'Tornillos para Madera',
    price: 120.00, 
    unit: created_units['box'], 
    especificaciones: '1.5", Phillips head, 100pcs',
    comments: 'For wood construction'
  },
  { 
    description: 'Concrete Anchors', 
    nombre: 'Taquetes para Concreto',
    price: 85.00, 
    unit: created_units['box'], 
    especificaciones: '3/8" x 2", 50pcs',
    comments: 'For mounting to concrete'
  },
  { 
    description: 'Door Hinge', 
    nombre: 'Bisagra para Puerta',
    price: 45.00, 
    unit: created_units['pr'], 
    especificaciones: '4" stainless steel',
    comments: 'Heavy duty'
  },
  { 
    description: 'Cabinet Handle', 
    nombre: 'Manija para Gabinete',
    price: 35.00, 
    unit: created_units['pcs'], 
    especificaciones: '5" brushed nickel',
    comments: 'Modern style'
  }
]

# Combine all material categories
all_materials = construction_materials + metal_materials + wood_materials + 
                glass_plastic_materials + finishing_materials + hardware_materials

# Create all materials
all_materials.each do |material_attrs|
  admin.materials.create!(material_attrs)
end

puts "Seed data created successfully!"
puts "Admin user: admin@example.com / password123"
puts "Created #{admin.units.count} units and #{admin.materials.count} materials"
