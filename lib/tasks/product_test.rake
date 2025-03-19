namespace :product do
  desc "Test the Product model with sample data"
  task test: :environment do
    # Find a user to associate with the product
    user = User.first
    if user.nil?
      puts "No users found. Please create a user first."
      next
    end
    
    puts "Creating a test product for user #{user.email}"
    
    # Create a new product with sample data
    product = user.products.build(
      description: "Test Product",
      data: {
        general_info: {
          width: 100,
          length: 200,
          quantity: 5,
          notes: "This is a test product"
        },
        materials: [
          {
            material_id: user.materials.first&.id,
            quantity: 2,
            notes: "Main material"
          }
        ],
        processes: [
          {
            process_id: user.manufacturing_processes.first&.id, 
            quantity: 1,
            notes: "Main process"
          }
        ],
        extras: [
          {
            extra_id: user.extras.first&.id,
            quantity: 3,
            notes: "Additional component"
          }
        ],
        pricing: {
          materials_cost: 0,
          processes_cost: 0,
          extras_cost: 0,
          total_cost: 0,
          margin_percentage: 30,
          sale_price: 0
        }
      }
    )
    
    if product.save
      puts "Product created successfully with ID: #{product.id}"
      
      # Test the getters
      puts "\nTesting getters:"
      puts "General Info: #{product.general_info.inspect}"
      puts "Materials: #{product.materials.inspect}"
      puts "Processes: #{product.processes.inspect}"
      puts "Extras: #{product.extras.inspect}"
      puts "Pricing: #{product.pricing.inspect}"
      
      # Test updating a section
      puts "\nTesting setters:"
      product.general_info = product.general_info.merge(width: 150)
      product.save
      puts "Updated width to 150: #{product.general_info['width']}"
      
      # Test calculations
      puts "\nTesting cost calculations:"
      product.calculate_totals
      product.save
      puts "Materials cost: #{product.pricing['materials_cost']}"
      puts "Processes cost: #{product.pricing['processes_cost']}"
      puts "Extras cost: #{product.pricing['extras_cost']}"
      puts "Total cost: #{product.pricing['total_cost']}"
      puts "Sale price: #{product.pricing['sale_price']}"
      
      # Test deep clone
      puts "\nTesting deep clone:"
      clone = product.deep_clone
      clone.save
      puts "Cloned product ID: #{clone.id}"
      puts "Cloned product description: #{clone.description}"
      puts "Original data equals clone data: #{product.data == clone.data}"
    else
      puts "Failed to create product:"
      puts product.errors.full_messages.join(", ")
    end
  end
end 