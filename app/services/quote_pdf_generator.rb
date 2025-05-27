class QuotePdfGenerator
  attr_reader :quote

  def initialize(quote)
    @quote = quote
  end

  def generate
    pdf_config = quote.user.pdf_config
    Prawn::Document.new(page_size: "LETTER", page_layout: :landscape, margin: [30, 30, 30, 30]) do |pdf|
      # Use default fonts with smaller base size
      pdf.font "Helvetica"
      pdf.font_size 8  # Reduced base font size
      
      # Define method to add header
      def add_header(pdf, pdf_config)
        # Save current cursor position
        original_cursor = pdf.cursor

        # Get logo URL from user's PDF config
        logo_url = pdf_config&.logo_url

        if logo_url.present?
          begin
            # Download the image from Cloudinary
            logo_tempfile = Down.download(logo_url)
            
            # Position logo higher than the top margin
            pdf.image logo_tempfile.path, 
                     width: 160, 
                     at: [0, pdf.bounds.top + 15],
                     position: :left,
                     vposition: :top,
                     fit: [160, 50],  # Constrain dimensions while maintaining aspect ratio
                     align: :left     # Align to left
            
            # Add quote number in the middle
            pdf.text_box "Cotización: #{quote.quote_number}",
                      at: [pdf.bounds.width/3, pdf.bounds.top + 15],
                      width: pdf.bounds.width/3,
                      align: :center,
                      size: 12,
                      style: :bold
            
            # Add date on the right
            pdf.text_box "Guadalajara, Jalisco. A #{quote.created_at.day} de #{month_name(quote.created_at.month).upcase} del #{quote.created_at.year}",
                      at: [0, pdf.bounds.top + 15],
                      width: pdf.bounds.width,
                      align: :right
                      
            # Clean up the tempfile
            logo_tempfile.close
            logo_tempfile.unlink
          rescue => e
            Rails.logger.error("Error including logo in PDF: #{e.message}")
            Rails.logger.error(e.backtrace.join("\n"))
            fallback_header(pdf)
          end
        else
          fallback_header(pdf)
        end

        # Move cursor down for separator line
        pdf.move_cursor_to pdf.bounds.top - 40
        pdf.stroke_horizontal_rule

        # Move cursor to where content should start
        pdf.move_cursor_to pdf.bounds.top - 50
      end

      def fallback_header(pdf)
        # Text-based placeholder logo
        pdf.text_box "Cotalo", at: [0, pdf.bounds.top + 15], size: 28, style: :bold
        
        # Add quote number in the middle
        pdf.text_box "Cotización: #{quote.quote_number}",
                  at: [pdf.bounds.width/3, pdf.bounds.top + 15],
                  width: pdf.bounds.width/3,
                  align: :center,
                  size: 12,
                  style: :bold
      end
      
      # Add header to first page
      add_header(pdf, pdf_config)
      
      # Add header to subsequent pages (except first)
      pdf.repeat(lambda { |pg| pg > 1 }) do
        add_header(pdf, pdf_config)
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
        "MEDIDAS INTERNAS (MM)",
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
          client_descriptions = []
          resistance_values = []
           
          # If there are materials in the product's JSON, collect all client descriptions
          if product.materials.present?
            product.materials.each do |material|
              # Get resistance value if present
              if material["resistance"].present?
                resistance_values << material["resistance"]
              end
              
              # Get client description if present
              if material["client_description"].present?
                client_descriptions << material["client_description"]
              end
            end
          end
          
          # Join all resistance values and client descriptions with comma and space
          resistance = resistance_values.any? ? resistance_values.join(", ") : "N/A"
          client_description = client_descriptions.any? ? client_descriptions.join(", ") : "N/A"
          
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
            0 => 8,   # FECHA
            1 => 14,  # PRODUCTO
            2 => 30,  # MEDIDAS (much larger for test)
            3 => 8,   # RESISTENCIA
            4 => 14,  # PAPEL
            5 => 5,   # ACABADOS (much smaller for test)
            6 => 12,  # CANTIDAD
            7 => 8    # PRECIO
          }
          
          # Calculate proportional widthsƒp
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
          
          # Track extras by name to prevent duplicates
          extras_by_name = {}
          
          # Add extras from data hash if present
          if product.data["extras"].present?
            product.data["extras"].each do |extra|
              name = extra["name"] || extra["description"]
              next unless name.present?
              extras_by_name[name] = extra
            end
          end
          
          # Add extras from the extras association if present
          if product.extras.present?
            product.extras.each do |extra|
              # Handle both hash and object formats
              name = extra.respond_to?(:description) ? extra.description : extra["name"] || extra["description"]
              next unless name.present?
              
              price = extra.respond_to?(:price) ? extra.price : extra["price"] || extra["unit_price"]
              quantity = extra.respond_to?(:quantity) ? extra.quantity : extra["quantity"] || 1

              extras_by_name[name] = {
                "name" => name,
                "price" => price,
                "quantity" => quantity
              }
            end
          end
          
          # Add extras from the product's JSON data if present
          if product.data["product_extras"].present?
            product.data["product_extras"].each do |extra|
              name = extra["name"] || extra["description"]
              next unless name.present?
              extras_by_name[name] = extra
            end
          end
          
          if extras_by_name.any?
            # Add product-specific header
            extras_data << ["HERRAMENTALES - #{product.description.upcase}", "PRECIO"]
            
            # Add extras for this product
            extras_by_name.each_value do |extra|
              name = extra["name"] || extra["description"]
              price = extra["price"] || extra["unit_price"] || 0
              quantity = extra["quantity"] || 1
              
              # Calculate total price if quantity > 1
              total_price = price.to_f * quantity
              
              # Format the price display with thousand separators
              price_display = if quantity > 1
                "$ #{helpers.number_with_delimiter(helpers.number_with_precision(total_price, precision: 2))} (#{quantity} x #{helpers.number_with_delimiter(helpers.number_with_precision(price.to_f, precision: 2))})"
              else
                "$ #{helpers.number_with_delimiter(helpers.number_with_precision(price.to_f, precision: 2))}"
              end
              
              # Add the extra to the table
              extras_data << [name.upcase, price_display]
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
      sales_conditions = [
        pdf_config&.sales_condition_1,
        pdf_config&.sales_condition_2,
        pdf_config&.sales_condition_3,
        pdf_config&.sales_condition_4
      ].select(&:present?)
      
      # Calculate height needed for sales conditions and footer
      conditions_height = (sales_conditions.length * 12) + 25  # 12 points per line + 25 for header
      footer_height = 100  # Height reserved for footer
      
      # Check if we need to move to next page for sales conditions
      if pdf.cursor < (conditions_height + footer_height)
        pdf.start_new_page
        add_header(pdf, pdf_config)
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
      def add_footer(pdf, pdf_config)
        # Save current cursor position
        original_cursor = pdf.cursor
        
        # Move to footer position - increased to 60 points to give more room
        pdf.move_cursor_to 80
        
        # Contact information (signature)
        begin
          contact_info = ""
          contact_info += pdf_config.signature_name.to_s if pdf_config&.signature_name.present?
          contact_info += " CORREO: #{pdf_config.signature_email}" if pdf_config&.signature_email.present?
          contact_info += " CEL/TEL: #{pdf_config.signature_phone}" if pdf_config&.signature_phone.present?
          contact_info += " WHATSAPP: #{pdf_config.signature_whatsapp}" if pdf_config&.signature_whatsapp.present?
          if contact_info.strip.present?
            pdf.text contact_info.strip, size: 8, style: :bold
          else
            pdf.text "Equipo Cotalo CORREO: gabriel@cotalo.app", size: 8, style: :bold
          end
        rescue StandardError => e
          Rails.logger.error("Error displaying signature in PDF: #{e.message}")
          # Professional default signature in case of error
          pdf.text "Equipo Cotalo CORREO: gabriel@cotalo.app", size: 8, style: :bold
        end
        
        pdf.move_down 5
        
        # Footer with sustainability message and horizontal rule
        pdf.stroke_horizontal_rule
        pdf.move_down 10

        # PDF custom footer text (user-defined)
        if pdf_config&.footer_text.present?
          pdf.fill_color '42b983'
          pdf.text pdf_config.footer_text, size: 8, align: :left, style: :normal
          pdf.fill_color '000000' # Reset to black
        end

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
        add_footer(pdf, pdf_config)
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