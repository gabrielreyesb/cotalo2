# Custom seed file to add manufacturing processes and extras to a specific user account

# Find the user by email
user = User.find_by(email: 'gabrielreyesb@gmail.com')

unless user
  puts "Error: User with email gabrielreyesb@gmail.com not found"
  exit
end

puts "Adding manufacturing processes and extras to user: #{user.email}"

# Create manufacturing processes
puts "Creating manufacturing processes..."
manufacturing_processes = [
  { 
    name: 'Laser Cutting', 
    description: 'Precise cutting using a high-powered laser beam. Ideal for intricate patterns and designs.',
    cost: 45.00
  },
  { 
    name: 'CNC Milling', 
    description: 'Computer-controlled machining process for creating precise shapes and forms from solid materials.',
    cost: 60.00
  },
  { 
    name: 'Welding', 
    description: 'Joining metal parts through melting and fusion. Various techniques available depending on material.',
    cost: 35.00
  },
  { 
    name: 'Powder Coating', 
    description: 'Durable and attractive finishing process that applies a dry powder to metal surfaces.',
    cost: 25.00
  },
  { 
    name: 'Screen Printing', 
    description: 'Method for applying designs onto surfaces using a mesh screen and ink.',
    cost: 15.00
  },
  { 
    name: 'Polishing', 
    description: 'Surface finishing to achieve smoothness, gloss, or remove oxidation.',
    cost: 12.00
  },
  { 
    name: 'Sand Blasting', 
    description: 'Surface preparation using abrasive materials propelled at high pressure.',
    cost: 20.00
  }
]

created_processes = []
manufacturing_processes.each do |process_attrs|
  process = user.manufacturing_processes.create!(process_attrs)
  created_processes << process
end

# Create extras
puts "Creating extras..."
extras = [
  { 
    name: 'Installation', 
    description: 'Professional installation service at the client site.',
    cost: 150.00
  },
  { 
    name: 'Delivery', 
    description: 'Delivery to client location within city limits.',
    cost: 75.00
  },
  { 
    name: 'Rush Order', 
    description: 'Expedited production and completion within 48 hours.',
    cost: 100.00
  },
  { 
    name: 'Custom Design', 
    description: 'Professional design services to create custom solutions.',
    cost: 200.00
  },
  { 
    name: 'Extended Warranty', 
    description: 'Additional 2-year warranty coverage beyond standard warranty.',
    cost: 50.00
  },
  { 
    name: 'Material Upgrade', 
    description: 'Upgrade to premium quality materials.',
    cost: 80.00
  }
]

created_extras = []
extras.each do |extra_attrs|
  extra = user.extras.create!(extra_attrs)
  created_extras << extra
end

puts "Seed data created successfully!"
puts "Created #{created_processes.size} manufacturing processes and #{created_extras.size} extras for user: #{user.email}" 