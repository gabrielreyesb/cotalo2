class QuotePdfGenerator
  attr_reader :quote

  def initialize(quote)
    @quote = quote
  end

  def generate
    Prawn::Document.new(page_size: "LETTER", page_layout: :landscape, margin: [30, 30, 30, 30]) do |pdf|
      # Use default fonts with smaller base size
      pdf.font "Helvetica"
      pdf.font_size 8  # Reduced base font size
      
      # Define method to add header
      def add_header(pdf)
        # Save current cursor position
        original_cursor = pdf.cursor

        # Add logo and date at the top
        logo_path = "#{Rails.root}/app/assets/images/logo.png"
        if File.exist?(logo_path) && File.size(logo_path) > 0
          begin
            # Position logo higher than the top margin
            pdf.image logo_path, width: 160, at: [0, pdf.bounds.top + 15]
            
            # Add quote number in the middle
            pdf.text_box "Cotización: #{quote.quote_number}",
                      at: [pdf.bounds.width/3, pdf.bounds.top + 15],
                      width: pdf.bounds.width/3,
                      align: :center,
                      size: 12,
                      style: :bold
            
            # Add date on the right
            pdf.text_box "Guadalajara, Jalisco. A #{Time.current.day} de #{month_name(Time.current.month).upcase} del #{Time.current.year}",
                      at: [0, pdf.bounds.top + 15],
                      width: pdf.bounds.width,
                      align: :right
          rescue StandardError => e
            Rails.logger.error("Error including logo in PDF: #{e.message}")
            # Fallback to text logo
            pdf.text_box "SURTIBOX", at: [0, pdf.bounds.top + 15], size: 24, style: :bold
            pdf.text_box "Soluciones en empaques y más...", at: [0, pdf.bounds.top - 10], size: 12, style: :italic
            
            # Add quote number in the middle even in fallback
            pdf.text_box "Cotización: #{quote.quote_number}",
                      at: [pdf.bounds.width/3, pdf.bounds.top + 15],
                      width: pdf.bounds.width/3,
                      align: :center,
                      size: 12,
                      style: :bold
          end
        else
          # No logo file - use text instead
          pdf.text_box "SURTIBOX", at: [0, pdf.bounds.top + 15], size: 24, style: :bold
          pdf.text_box "Soluciones en empaques y más...", at: [0, pdf.bounds.top - 10], size: 12, style: :italic
          
          # Add quote number in the middle even without logo
          pdf.text_box "Cotización: #{quote.quote_number}",
                    at: [pdf.bounds.width/3, pdf.bounds.top + 15],
                    width: pdf.bounds.width/3,
                    align: :center,
                    size: 12,
                    style: :bold
        end

        # Move cursor down for separator line
        pdf.move_cursor_to pdf.bounds.top - 40
        pdf.stroke_horizontal_rule

        # Move cursor to where content should start
        pdf.move_cursor_to pdf.bounds.top - 50
      end
      
      # Add header to first page
      add_header(pdf)
      
      # Add header to subsequent pages (except first)
      pdf.repeat(lambda { |pg| pg > 1 }) do
        add_header(pdf)
      end
      
      # Ensure we start at the right position after header
      pdf.move_cursor_to pdf.bounds.top - 50
      
      # Start content after header
      [
        ["Cliente:", quote.customer_name],
        ["Empresa:", quote.organization || 'N/A'],
        ["Correo:", quote.email || 'N/A'],
        ["Teléfono:", quote.telephone || 'N/A'],
        ["Proyecto:", quote.project_name]
      ].each do |label, value|
        pdf.text_box label, 
          at: [0, pdf.cursor],
          width: 80,
          size: 9
        pdf.text_box value,
          at: [80, pdf.cursor],
          size: 9,
          style: :bold
        pdf.move_down 15
      end
      
      pdf.move_down 15
      
      # Add Products legend
      pdf.text "Productos:", size: 9, style: :bold
      pdf.move_down 5
      
      # Products Table Header
      products_header = [
        "FECHA",
        "PRODUCTO", 
        "MEDIDA\nINTERNAS MM\n(L, A, AL)", 
        "RESISTENCIA", 
        "PAPEL", 
        "ACABADOS",
        "CANTIDAD", 
        "PRECIO"
      ]
      
      # Initialize products data with header
      products_data = [products_header]
      
      # Add product data rows
      if quote.quote_products.any?
        quote.quote_products.each do |quote_product|
          product = quote_product.product
          unit_price = product.pricing.try(:[], "final_price_per_piece") || 0
          
          # Get product details (using default values if not available)
          product_info = product.general_info
           
          # Get internal measurements directly and format it
          internal_measures = "N/A"
          if product_info["inner_measurements"].present?
            measurements = product_info["inner_measurements"]
             
            # Check if we have a hash with length, width, height
            if measurements.is_a?(Hash) && measurements["length"].present? && measurements["width"].present? && measurements["height"].present?
              internal_measures = "#{measurements['length']} x #{measurements['width']} x #{measurements['height']}"
            elsif measurements.is_a?(String) && measurements.present?
              # If it's already a formatted string, use it directly
              internal_measures = measurements
            end
          end
           
          # Get resistance from the materials
          resistance = "N/A"
          client_description = "N/A"
           
          # If there are materials in the product's JSON, use the first one or the selected one
          if product.materials.present?
            selected_material = product.materials.find { |m| m["id"].to_s == product_info["selected_material_id"].to_s }
            material = selected_material || product.materials.first
             
            # Use resistance and client_description from the stored material data
            resistance = material["resistance"] if material && material["resistance"].present?
            client_description = material["client_description"] if material && material["client_description"].present?
          end
          
          # Combine all processes into a single string
          process_descriptions = []
          
          # Get processes descriptions directly from the product's processes array
          if product.processes.present?
            process_descriptions = product.processes.map { |process| process["description"] }.compact
          end
          
          # Join all processes with comma and space
          processes_text = process_descriptions.any? ? process_descriptions.join(", ") : "N/A"
          
          # Get quantity from product info
          quantity = product_info["quantity"] || quote_product.quantity
          
          # Add row to products data
          products_data << [
            Time.current.strftime("%d/%m/%Y"),
            product.description,
            internal_measures,
            resistance,
            client_description,
            processes_text,
            helpers.number_with_delimiter(quantity),
            "$ #{helpers.number_with_precision(unit_price.to_f, precision: 2)}"
          ]
        end
        
        # Create products table
        pdf.table products_data, header: true do |t|
          # Style all cells
          t.cells.padding = [5, 3, 5, 3]  # Slightly reduce padding
          t.cells.borders = [:left, :right, :top, :bottom]
          t.cells.border_width = 0.5
          
          # Style header row
          t.row(0).font_style = :bold
          t.row(0).align = :center
          t.row(0).background_color = "DDDDDD"
          t.row(0).size = 8  # Smaller header font
          
          # Set relative column widths
          column_widths = {
            0 => 10,  # FECHA
            1 => 15,  # PRODUCTO
            2 => 12,  # MEDIDA
            3 => 10,  # RESISTENCIA
            4 => 15,  # PAPEL
            5 => 15,  # ACABADOS
            6 => 8,   # CANTIDAD
            7 => 8    # PRECIO
          }
          
          # Calculate proportional widths
          total_proportion = column_widths.values.sum
          available_width = pdf.bounds.width
          
          column_widths.each do |col, proportion|
            t.column(col).width = (proportion.to_f / total_proportion) * available_width
          end
          
          # Align cells
          t.column(0).align = :left      # Product name left-aligned
          t.column(1..5).align = :center # Most columns centered
          t.column(6).align = :center    # Quantity centered
          t.column(7).align = :right     # Price right-aligned
          
          # Add light gray background to alternate rows for better readability
          t.cells.borders = [:left, :right, :top, :bottom]
          t.cells.border_width = 0.5
          t.cells.border_color = "CCCCCC"
          
          # Set cell font size
          t.cells.size = 8  # Smaller content font
        end
        
        # Add "IVA NO INCLUIDO" text
        pdf.move_down 5
        pdf.text "IVA NO INCLUIDO", align: :right, size: 9, style: :bold
      else
        pdf.text "No hay productos en esta cotización", style: :italic
      end
      
      # Add extras (herramentales) section
      pdf.move_down 10
      
      # Create extras table with header
      extras_data = []
      
      # Get extras from the products
      if quote.quote_products.any?
        quote.quote_products.each do |quote_product|
          product = quote_product.product
          
          if product.data["extras"].present? && product.data["extras"].any?
            # Add product-specific header
            extras_data << ["HERRAMENTALES - #{product.description.upcase}", "PRECIO"]
            
            # Add extras for this product
            product.data["extras"].each do |extra|
              name = extra["name"] || extra["description"]
              price = extra["price"] || extra["unit_price"] || 0
              quantity = extra["quantity"] || 1
              
              # Format the price display with thousand separators
              price_display = if quantity > 1
                "$ #{helpers.number_with_delimiter(helpers.number_with_precision(price.to_f, precision: 2))} x #{quantity}"
              else
                "$ #{helpers.number_with_delimiter(helpers.number_with_precision(price.to_f, precision: 2))}"
              end
              
              # Only add if we have a name and price
              extras_data << [name.upcase, price_display] if name.present?
            end
          end
        end
      end
      
      # Add extras (herramentales) section if any exist
      if extras_data.any?
        # Calculate height needed for extras table (approximate)
        extras_height = (extras_data.length * 20) + 20  # 20 points per row + margin
        footer_height = 80  # Height reserved for footer
        
        # Check if we need to move to next page for extras table
        if pdf.cursor < (extras_height + footer_height)
          pdf.start_new_page
        end
        
        # Create extras table
        pdf.table extras_data, width: 350 do |t|
          t.cells.padding = [6, 4, 6, 4]
          t.cells.borders = [:left, :right, :top, :bottom]
          t.cells.border_width = 0.5
          
          # Style all product headers
          extras_data.each_with_index do |row, i|
            if row[0].to_s.start_with?("HERRAMENTALES -")
              t.row(i).font_style = :bold
              t.row(i).background_color = "DDDDDD"
              t.row(i).column(1).align = :right  # Align "PRECIO" header to the right
            end
          end
          
          # Adjust column widths
          t.column(0).width = 230
          t.column(1).width = 120
          
          # Align prices right
          t.column(1).align = :right
        end
      end
      
      # Add some space after extras table
      pdf.move_down 20
      
      # Get sales conditions
      sales_conditions = quote.user.sales_conditions.select(&:present?)
      
      # Calculate height needed for sales conditions and footer
      conditions_height = (sales_conditions.length * 12) + 25  # 12 points per line + 25 for header
      footer_height = 100  # Height reserved for footer
      
      # Check if we need to move to next page for sales conditions
      if pdf.cursor < (conditions_height + footer_height)
        pdf.start_new_page
        add_header(pdf)
      end
      
      # Sales Conditions
      pdf.text "CONDICIONES DE VENTA", size: 8, style: :bold
      
      # Add bullet points for conditions
      pdf.font_size 8 do
        sales_conditions.each do |condition|
          pdf.text "• #{condition.upcase}"
        end
      end

      # Define a method to add the footer
      def add_footer(pdf)
        # Save current cursor position
        original_cursor = pdf.cursor
        
        # Move to footer position - increased to 60 points to give more room
        pdf.move_cursor_to 80
        
        # Contact information (signature)
        begin
          signature = quote.user.signature_info
          Rails.logger.info("PDF Signature Info: #{signature.inspect}")
          
          contact_info = signature[:name].to_s
          contact_info += " CORREO: #{signature[:email]}" if signature[:email].present?
          contact_info += " CEL/TEL: #{signature[:phone]}" if signature[:phone].present?
          contact_info += " WHATSAPP: #{signature[:whatsapp]}" if signature[:whatsapp].present?
          
          if contact_info.present?
            pdf.text contact_info, size: 8, style: :bold
          else
            pdf.text "Jonathan Gabriel Rubio Huerta", size: 8, style: :bold
          end
        rescue StandardError => e
          Rails.logger.error("Error displaying signature in PDF: #{e.message}")
          # Fallback signature in case of error
          pdf.text "Jonathan Gabriel Rubio Huerta", size: 8, style: :bold
        end
        
        pdf.move_down 5
        
        # Footer with sustainability message and horizontal rule
        pdf.stroke_horizontal_rule
        pdf.move_down 10
        
        # Green text for sustainability message
        pdf.fill_color "009933"
        pdf.text "Fabricamos con materiales sustentables que protegen al medio ambiente...", 
                size: 8, 
                style: :italic, 
                align: :left
        pdf.fill_color "000000" # Reset to black
        
        # Add more space for the logos
        pdf.move_down 15
        
        # Use logos from the public directory (works in all environments)
        begin
          # FSC/Bosques logo (left)
          pdf.image "#{Rails.root}/public/images/Bosques.png", 
                    width: 45, 
                    at: [pdf.bounds.width - 150, pdf.cursor]
        rescue StandardError => e
          Rails.logger.error("Error including FSC logo in PDF: #{e.message}")
        end
        
        begin
          # FDA logo (center-right)
          pdf.image "#{Rails.root}/public/images/FDA.jpg", 
                    width: 45, 
                    at: [pdf.bounds.width - 95, pdf.cursor]
        rescue StandardError => e
          Rails.logger.error("Error including FDA logo in PDF: #{e.message}")
        end
        
        begin
          # QR code (right)
          pdf.image "#{Rails.root}/public/images/qr-code.png", 
                    width: 35, 
                    at: [pdf.bounds.width - 40, pdf.cursor]
        rescue StandardError => e
          Rails.logger.error("Error including QR code in PDF: #{e.message}")
        end
      end
      
      # Add footer to all pages
      pdf.repeat :all do
        add_footer(pdf)
      end
    end.render
  end

  private

  def helpers
    ActionController::Base.helpers
  end
  
  def month_name(month)
    {
      1 => "enero", 2 => "febrero", 3 => "marzo", 4 => "abril",
      5 => "mayo", 6 => "junio", 7 => "julio", 8 => "agosto",
      9 => "septiembre", 10 => "octubre", 11 => "noviembre", 12 => "diciembre"
    }[month]
  end
end 