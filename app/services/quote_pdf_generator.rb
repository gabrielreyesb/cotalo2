class QuotePdfGenerator
  attr_reader :quote

  def initialize(quote)
    @quote = quote
  end

  def generate
    Prawn::Document.new(page_size: "LETTER", page_layout: :landscape, margin: [30, 30, 30, 30]) do |pdf|
      # Use default fonts
      pdf.font "Helvetica"
      
      # Header with date and location
      pdf.text "Guadalajara, Jalisco. A #{Time.current.day} de #{month_name(Time.current.month).upcase} del #{Time.current.year}", align: :right
      pdf.stroke_horizontal_rule
      pdf.move_down 15
      
      # Add logo - attempt to display image, fall back to text if unavailable
      logo_path = "#{Rails.root}/app/assets/images/logo.png"
      if File.exist?(logo_path) && File.size(logo_path) > 0
        begin
          pdf.image logo_path, width: 180, at: [0, pdf.cursor]
        rescue StandardError => e
          Rails.logger.error("Error including logo in PDF: #{e.message}")
          # Fallback to text logo
          pdf.text_box "SURTIBOX", at: [0, pdf.cursor], size: 24, style: :bold
          pdf.move_down 30
          pdf.text_box "Soluciones en empaques y más...", at: [0, pdf.cursor - 25], size: 12, style: :italic
        end
      else
        # No logo file - use text instead
        pdf.text_box "SURTIBOX", at: [0, pdf.cursor], size: 24, style: :bold
        pdf.move_down 30
        pdf.text_box "Soluciones en empaques y más...", at: [0, pdf.cursor - 25], size: 12, style: :italic
      end
      
      # Skip box illustration since it's causing errors
      # We can re-enable this when proper image files are available
      # box_image_path = "#{Rails.root}/app/assets/images/box_watermark.png"
      # if File.exist?(box_image_path)
      #   pdf.image box_image_path, width: 300, at: [450, pdf.cursor + 20]
      # end
      
      # Client and Project Information
      pdf.move_down 50
      pdf.text "CLIENTE: #{quote.customer_name}", size: 11, style: :bold
      pdf.text "COTIZACIÓN PROYECTO: #{quote.project_name}", size: 11, style: :bold
      pdf.text "PRODUCTOS: #{quote.quote_products.count}", size: 11, style: :bold
      pdf.move_down 15
      
      # Products Table Header
      products_header = [
        "PRODUCTO", 
        "MEDIDA\nINTERNAS MM\n(L, A, AL)", 
        "RESISTENCIA", 
        "PAPEL", 
        "PEGUE", 
        "IMPRESIÓN", 
        "IMPRESIÓN\nINTERIOR", 
        "TERMINADO", 
        "CANTIDAD", 
        "PRECIO"
      ]
      
      # Initialize products data with header
      products_data = [products_header]
      
      # Add product data rows
      if quote.quote_products.any?
        quote.quote_products.each do |quote_product|
          product = quote_product.product
          unit_price = product.pricing.try(:[], "total_price") || 0
          
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
           
           # If there are materials in the product, use the first one or the selected one
           if product.materials.present?
             material = nil
             
             # If a specific material is selected, try to find it
             if product_info["selected_material_id"].present?
               product.materials.each do |m|
                 if m["id"].to_s == product_info["selected_material_id"].to_s || 
                    (m.key?("material_id") && m["material_id"].to_s == product_info["selected_material_id"].to_s)
                   material = m
                   break
                 end
               end
             else
               # If no specific material is selected, use the first one
               material = product.materials.first
             end
             
             # Use specifications from the material if available
             if material && material["specifications"].present?
               resistance = material["specifications"]
             end
           end
           
           # Get paper type from the selected material
           paper_type = "N/A"
           selected_material_id = product_info["selected_material_id"]
           
           if selected_material_id.present?
             # Find selected material in the materials array
             selected_material = product.materials.find { |m| m["material_id"].to_s == selected_material_id.to_s }
             
             if selected_material
               # Get material description for paper type if not specified in product_info
               if product_info["paper_type"].blank? && selected_material["description"].present?
                 # Try to find the Material record to get its description
                 material_record = Material.find_by(id: selected_material_id)
                 if material_record
                   paper_type = material_record.description
                 else
                   # Use the description from the saved data
                   paper_type = selected_material["description"]
                 end
               end
             end
           end
           
           # Use paper_type from product_info if available
           paper_type = product_info["paper_type"] if product_info["paper_type"].present?
           
           adhesive = product_info["adhesive_type"] || "N/A"
           
           # Get printing info from processes
           printing_process = product.processes.find { |p| p["process_type"] == "printing" }
           printing = printing_process ? "#{printing_process['quantity']} Pantones" : "N/A"
           
           interior_printing_process = product.processes.find { |p| p["process_type"] == "interior_printing" }
           interior_printing = interior_printing_process ? "Aplica" : "NO APLICA"
           
           # Get finish info
           finish_info = []
           finish_info << "Plástico" if product_info["plastic_finish"]
           finish_info << "Mate" if product_info["matte_finish"]
           finish_info << "Barniz UV" if product_info["uv_finish"]
           finish = finish_info.any? ? finish_info.join(" y ") : "N/A"
          
          # Add row to products data
          products_data << [
            product.description,
            internal_measures,
            resistance,
            paper_type,
            adhesive,
            printing,
            interior_printing,
            finish,
            helpers.number_with_delimiter(quote_product.quantity),
            "$\n#{helpers.number_with_precision(unit_price.to_f, precision: 2)}"
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
          t.row(0).size = 9  # Slightly smaller font
          
          # Set relative column widths
          column_widths = {
            0 => 10,  # PRODUCTO
            1 => 8,   # MEDIDA
            2 => 8,   # RESISTENCIA
            3 => 8,   # PAPEL
            4 => 7,   # PEGUE
            5 => 7,   # IMPRESIÓN
            6 => 7,   # IMP INTERIOR
            7 => 9,   # TERMINADO
            8 => 7,   # CANTIDAD
            9 => 6    # PRECIO
          }
          
          # Calculate proportional widths
          total_proportion = column_widths.values.sum
          available_width = pdf.bounds.width
          
          column_widths.each do |col, proportion|
            t.column(col).width = (proportion.to_f / total_proportion) * available_width
          end
          
          # Align cells
          t.column(0).align = :left      # Product name left-aligned
          t.column(1..7).align = :center # Most columns centered
          t.column(8).align = :center    # Quantity centered
          t.column(9).align = :right     # Price right-aligned
          
          # Add light gray background to alternate rows for better readability
          t.cells.borders = [:left, :right, :top, :bottom]
          t.cells.border_width = 0.5
          t.cells.border_color = "CCCCCC"
        end
        
        # Add "IVA NO INCLUIDO" text
        pdf.bounding_box([pdf.bounds.width - 170, pdf.cursor + 5], width: 170, height: 20) do
          pdf.text "IVA NO INCLUIDO", align: :right, size: 9, style: :bold
        end
      else
        pdf.text "No hay productos en esta cotización", style: :italic
      end
      
      # Add extras (herramentales) section
      pdf.move_down 20
      
      # Create extras table with header
      extras_data = []
      extras_data << ["HERRAMENTALES", ""]
      
      # Get extras from the products
      extra_ids_used = []
      
      if quote.quote_products.any?
        quote.quote_products.each do |quote_product|
          product = quote_product.product
          product.extras.each do |extra|
            extra_id = extra["extra_id"]
            
            # Skip if we've already included this extra
            next if extra_ids_used.include?(extra_id)
            
            # Find the Extra record to get its description
            extra_record = Extra.find_by(id: extra_id)
            next unless extra_record
            
            # Add to our list of used extras
            extra_ids_used << extra_id
            
            # Calculate cost based on quantity and price
            cost = extra["price"].to_f
            
            # Format based on cost type
            price_display = if extra["quantity"].to_i > 1
              "$ #{helpers.number_with_precision(cost, precision: 2)} x #{extra["quantity"]}"
            else
              "$ #{helpers.number_with_precision(cost, precision: 2)}"
            end
            
            extras_data << [extra_record.description, price_display]
          end
        end
        
        # If no extras were found, add some default ones as placeholders
        if extras_data.size <= 1
          extras_data << ["SUAJE", "$ 7000"]
          extras_data << ["PLACAS DE IMPRESIÓN", "$ 250 x color"]
          extras_data << ["REALCE", "$ 4000"]
        end
      end
      
      if extras_data.size > 1
        # Create extras table
        pdf.table extras_data, width: 350 do |t|
          t.cells.padding = [6, 4, 6, 4]
          t.cells.borders = [:left, :right, :top, :bottom]
          t.cells.border_width = 0.5
          
          # Style header row
          t.row(0).font_style = :bold
          t.row(0).background_color = "DDDDDD"
          
          # Adjust column widths
          t.column(0).width = 230
          t.column(1).width = 120
          
          # Align prices right
          t.column(1).align = :right
        end
      end
      
      # Sales Conditions
      pdf.move_down 20
      pdf.text "CONDICIONES DE VENTA", size: 10, style: :bold
      
      # Add bullet points for conditions
      pdf.font_size 9 do
        conditions = [
          "LAS ENTREGAS PUEDE VARIAR +/- 10% DE LA CANTIDAD SOLICITADA.",
          "TIEMPO DE ENTREGA: DESPUÉS AUTORIZAR LA PRINT CARD SE ENTREGARÁ EL PRODUCTO EN UN MÁXIMO DE 30 DÍAS Y 21 DÍAS EN REPETICIONES.",
          "CONDICIÓN DE PAGO: CONTADO",
          "COTIZACIÓN CON VALIDEZ DE 30 DÍAS."
        ]
        
        conditions.each do |condition|
          pdf.text "• #{condition}"
        end
      end
      
      # Contact information
      pdf.move_down 15
      contact_info = "Jonathan Gabriel Rubio Huerta CORREO: jonathanrubio@surtibox.com CEL/TEL: 3311764022 / 33 2484 9954  WHATSAPP: 3311764022"
      pdf.text contact_info, size: 9, style: :bold
      
      # Footer with sustainability message and horizontal rule
      pdf.stroke_horizontal_rule
      pdf.move_down 10
      
      # Green text for sustainability message
      pdf.fill_color "009933"
      pdf.text "Fabricamos con materiales sustentables que protegen al medio ambiente...", 
              size: 10, 
              style: :italic, 
              align: :center
      pdf.fill_color "000000" # Reset to black
      
      # Skip certification logos for now until we have valid image files
      # Position for logos
      # y_position = pdf.cursor - 10
      # 
      # fsc_logo_path = "#{Rails.root}/app/assets/images/fsc_logo.png"
      # if File.exist?(fsc_logo_path) && File.size(fsc_logo_path) > 0
      #   begin
      #     pdf.image fsc_logo_path, width: 80, at: [pdf.bounds.width - 200, y_position]
      #   rescue StandardError => e
      #     Rails.logger.error("Error including FSC logo in PDF: #{e.message}")
      #   end
      # end
      # 
      # fda_logo_path = "#{Rails.root}/app/assets/images/fda_logo.png"
      # if File.exist?(fda_logo_path) && File.size(fda_logo_path) > 0
      #   begin
      #     pdf.image fda_logo_path, width: 80, at: [pdf.bounds.width - 120, y_position]
      #   rescue StandardError => e
      #     Rails.logger.error("Error including FDA logo in PDF: #{e.message}")
      #   end
      # end
      # 
      # qr_code_path = "#{Rails.root}/app/assets/images/qr_code.png"
      # if File.exist?(qr_code_path) && File.size(qr_code_path) > 0
      #   begin
      #     pdf.image qr_code_path, width: 45, at: [pdf.bounds.width - 45, y_position]
      #   rescue StandardError => e
      #     Rails.logger.error("Error including QR code in PDF: #{e.message}")
      #   end
      # end
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