require 'down'

class QuotePdfGeneratorDetailed
  attr_reader :quote

  def initialize(quote)
    @quote = quote
  end

  def generate
    # Suprimir advertencia de fuentes
    Prawn::Fonts::AFM.hide_m17n_warning = true
    
    pdf_config = quote.user.pdf_config
    Prawn::Document.new(page_size: "LETTER", page_layout: :portrait, margin: [30, 30, 30, 30]) do |pdf|
      # Use default fonts
      pdf.font "Helvetica"
      pdf.font_size 10
      
      # Define method to add header (igual al original)
      def add_header(pdf, pdf_config)
        # Get logo URL from user's PDF config
        logo_url = pdf_config&.logo_url

        if logo_url.present?
          begin
            # Download the image from Cloudinary
            logo_tempfile = Down.download(logo_url)
            
            # Position logo in the top left corner
            pdf.image logo_tempfile.path, 
                     width: 120, 
                     at: [0, pdf.bounds.top + 15],
                     position: :left,
                     vposition: :top,
                     fit: [120, 40]
            
            # Clean up the tempfile
            logo_tempfile.close
            logo_tempfile.unlink
          rescue => e
            fallback_header(pdf)
          end
        else
          fallback_header(pdf)
        end
        
        # Add quote number on the right
        pdf.text_box "Cotización: #{quote.quote_number}",
                  at: [pdf.bounds.width - 200, pdf.bounds.top + 10],
                  width: 200,
                  align: :right,
                  size: 10,
                  style: :bold
        
        # Add date on the right, below quote number
        pdf.text_box "Guadalajara, Jalisco. A #{quote.created_at.day} de #{month_name(quote.created_at.month).upcase} del #{quote.created_at.year}",
                  at: [pdf.bounds.width - 200, pdf.bounds.top - 5],
                  width: 200,
                  align: :right,
                  size: 9

        # Move cursor down for separator line
        pdf.move_cursor_to pdf.bounds.top - 30
        pdf.stroke_horizontal_rule

        # Move cursor to where content should start
        pdf.move_cursor_to pdf.bounds.top - 40
      end

      def fallback_header(pdf)
        # Text-based placeholder logo on the left
        pdf.text_box "Cotalo", at: [0, pdf.bounds.top + 15], size: 24, style: :bold
        
        # Add quote number on the right
        pdf.text_box "Cotización: #{quote.quote_number}",
                  at: [pdf.bounds.width - 200, pdf.bounds.top + 10],
                  width: 200,
                  align: :right,
                  size: 10,
                  style: :bold
        
        # Add date on the right, below quote number
        pdf.text_box "Guadalajara, Jalisco. A #{quote.created_at.day} de #{month_name(quote.created_at.month).upcase} del #{quote.created_at.year}",
                  at: [pdf.bounds.width - 200, pdf.bounds.top - 5],
                  width: 200,
                  align: :right,
                  size: 9
      end
      
      # Add header to first page
      add_header(pdf, pdf_config)
      
      # Add header to subsequent pages (except first)
      pdf.repeat(lambda { |pg| pg > 1 }) do
        add_header(pdf, pdf_config)
      end
      
      # Ensure we start at the right position after header
      pdf.move_cursor_to pdf.bounds.top - 50
      
      # Customer information (solo en la primera página)
      add_customer_info(pdf)
      
      # Process each product on separate pages
      quote.quote_products.each_with_index do |quote_product, index|
        # Start new page for each product (except the first one)
        if index > 0
          pdf.start_new_page
          add_header(pdf, pdf_config)
        end
        
        product = quote_product.product
        add_product_page(pdf, product, quote_product, index + 1, pdf_config)
      end
      
      # Add footer to all pages
      pdf.repeat :all do
        add_footer(pdf, pdf_config)
      end
    end.render
  end

  private

  def add_customer_info(pdf)
    # Save current cursor position for background rectangle
    start_y = pdf.cursor
    
    # Calculate approximate height needed for the customer info block
    # 3 lines of text + spacing = approximately 60 points
    block_height = 60
    
    # Add padding above the text (start the background a bit higher)
    padding_top = 10
    background_start_y = start_y + padding_top
    background_height = block_height + padding_top
    
    # Draw background rectangle with very light grey FIRST
    pdf.fill_color "F5F5F5"  # Very light grey
    pdf.fill_rectangle [0, background_start_y], pdf.bounds.width, background_height
    pdf.fill_color "000000"  # Reset to black
    
    # Cliente y Empresa en el mismo renglón
    pdf.text_box "Cliente:", 
      at: [0, pdf.cursor],
      width: 80,
      size: 10
    pdf.text_box quote.customer_name,
      at: [80, pdf.cursor],
      size: 10,
      style: :bold
    pdf.text_box "Empresa:", 
      at: [250, pdf.cursor],
      width: 80,
      size: 10
    pdf.text_box quote.organization || 'N/A',
      at: [330, pdf.cursor],
      size: 10,
      style: :bold
    pdf.move_down 15
    
    # Correo y Teléfono en el mismo renglón
    pdf.text_box "Correo:", 
      at: [0, pdf.cursor],
      width: 80,
      size: 10
    pdf.text_box quote.email || 'N/A',
      at: [80, pdf.cursor],
      size: 10,
      style: :bold
    pdf.text_box "Teléfono:", 
      at: [250, pdf.cursor],
      width: 80,
      size: 10
    pdf.text_box quote.telephone || 'N/A',
      at: [330, pdf.cursor],
      size: 10,
      style: :bold
    pdf.move_down 15
    
    # Proyecto en el mismo bloque de información
    pdf.text_box "Proyecto:", 
      at: [0, pdf.cursor],
      width: 80,
      size: 10
    pdf.text_box quote.project_name,
      at: [80, pdf.cursor],
      size: 10,
      style: :bold
    pdf.move_down 15
    
    pdf.move_down 20
  end



  def add_product_page(pdf, product, quote_product, product_number, pdf_config)
    # Product title
    pdf.text "Producto: #{product.description}", size: 12, style: :bold
    pdf.move_down 1
    
    # Product general info
    product_info = product.general_info
    quantity = product_info["quantity"] || quote_product.quantity
    
    # Get product dimensions
    width = product_info["width"] || "N/A"
    length = product_info["length"] || "N/A"
    
    # Create table with piezas, ancho y largo en el mismo renglón
    product_details = [
      ["Piezas", helpers.number_with_delimiter(quantity), "Ancho", width != "N/A" ? "#{width} cm" : "N/A", "Largo", length != "N/A" ? "#{length} cm" : "N/A"]
    ]
    
    # Filter out N/A values for cleaner display
    product_details = product_details.map do |row|
      row.map { |cell| cell == "N/A" ? nil : cell }.compact
    end
    
    if product_details.any?
      pdf.table product_details do |t|
        t.cells.padding = [4, 8, 4, 8]
        t.cells.borders = [:left, :right, :top, :bottom]
        t.cells.border_width = 0.5
        t.cells.border_color = "CCCCCC"
        
        # Style header columns (Piezas, Ancho, Largo)
        t.column(0).font_style = :bold
        t.column(0).background_color = "42b983"
        t.column(0).text_color = "FFFFFF"
        t.column(0).width = 80  # Piezas label
        t.column(1).width = 104 # Piezas value
        t.column(2).font_style = :bold
        t.column(2).background_color = "42b983"
        t.column(2).text_color = "FFFFFF"
        t.column(2).width = 80  # Ancho label
        t.column(3).width = 104 # Ancho value
        t.column(4).font_style = :bold
        t.column(4).background_color = "42b983"
        t.column(4).text_color = "FFFFFF"
        t.column(4).width = 80  # Largo label
        t.column(5).width = 104 # Largo value
        
        # Align cells
        t.column(0..-1).align = :center
      end
    end
    
    pdf.move_down 25
    
    # Materials and Processes Table
    add_materials_processes_table(pdf, product)
    pdf.move_down 10
    
    # Global Processes
    add_global_processes_section(pdf, product)
    pdf.move_down 20
    
    # Indirect Costs
    add_indirect_costs_section(pdf, product)
    pdf.move_down 20
    
    # Total costs at the bottom
    add_total_costs(pdf, product)
    
    # Sales conditions from pdf_config
    add_sales_conditions(pdf, pdf_config)
  end

  def add_materials_processes_table(pdf, product)
    
    if product.materials.present?
      product.materials.each_with_index do |material, material_index|
        # Material header
        material_name = material["name"] || material["description"] || "Material #{material_index + 1}"
        material_cost = material["totalPrice"] || material["cost"] || material["price"] || 0
        
        # Material header
        pdf.text "Material: #{material_name.upcase}", size: 11, style: :bold
        pdf.move_down 1
        
        # Processes for this material
        material_processes = material["processes"] || []
        

        
        # Processes table - simplified with only description
        processes_data = [["Procesos aplicados"]]
        
        if material_processes.any?
          material_processes.each do |process|
            process_name = process["name"] || process["description"] || "N/A"
            
            processes_data << [process_name]
          end
        else
          # Add row for "Sin proceso aplicado" (singular)
          processes_data << ["Sin proceso aplicado"]
        end
        
        # Always render the table
        pdf.table processes_data, header: true, width: pdf.bounds.width do |t|
          t.cells.padding = [4, 4, 4, 4]
          t.cells.borders = [:left, :right, :top, :bottom]
          t.cells.border_width = 0.5
          t.cells.border_color = "CCCCCC"
          
          # Style header row
          t.row(0).font_style = :bold
          t.row(0).background_color = "42b983"
          t.row(0).text_color = "FFFFFF"
          t.row(0).align = :center
          
          # Set column width - full width for description
          t.column(0).width = pdf.bounds.width
          
          # Align cells
          t.column(0).align = :left
        end
        
        pdf.move_down 10
      end
    else
      pdf.text "No hay materiales registrados", style: :italic
    end
  end

  def add_global_processes_section(pdf, product)
    pdf.text "Procesos globales", size: 12, style: :bold
    pdf.move_down 1
    
    # Los procesos globales son aquellos que no tienen materialId
    global_processes = product.processes&.select { |process| !process["materialId"] } || []
    
    if global_processes.any?
      table_data = [["Proceso"]]
      
      global_processes.each do |process|
        table_data << [
          process["name"] || process["description"] || "N/A"
        ]
      end
      
              pdf.table table_data, header: true, width: pdf.bounds.width do |t|
          t.cells.padding = [6, 4, 6, 4]
          t.cells.borders = [:left, :right, :top, :bottom]
          t.cells.border_width = 0.5
          t.cells.border_color = "CCCCCC"
          
          # Style header row
          t.row(0).font_style = :bold
          t.row(0).align = :center
          t.row(0).background_color = "42b983"
          t.row(0).text_color = "FFFFFF"
          
          # Set column width - full width for process
          t.column(0).width = pdf.bounds.width
          
          # Align cells
          t.column(0).align = :left
        end
    else
      pdf.text "No hay procesos globales registrados", style: :italic
    end
  end

  def add_indirect_costs_section(pdf, product)
    pdf.text "Costos indirectos", size: 12, style: :bold
    pdf.move_down 1
    
    # Los costos indirectos están en product.extras
    indirect_costs = product.extras || []
    
    if indirect_costs.any?
      table_data = [["Concepto"]]
      
      indirect_costs.each do |cost|
        table_data << [
          cost["name"] || cost["description"] || "N/A"
        ]
      end
      
              pdf.table table_data, header: true, width: pdf.bounds.width do |t|
          t.cells.padding = [6, 4, 6, 4]
          t.cells.borders = [:left, :right, :top, :bottom]
          t.cells.border_width = 0.5
          t.cells.border_color = "CCCCCC"
          
          # Style header row
          t.row(0).font_style = :bold
          t.row(0).align = :center
          t.row(0).background_color = "42b983"
          t.row(0).text_color = "FFFFFF"
          
          # Set column width - full width for concept
          t.column(0).width = pdf.bounds.width
          
          # Align cells
          t.column(0).align = :left
        end
    else
      pdf.text "No hay costos indirectos registrados", style: :italic
    end
  end

  def add_product_summary(pdf, product, quote_product)
    pdf.text "RESUMEN DEL PRODUCTO", size: 12, style: :bold
    pdf.move_down 10
    
    # Get pricing information
    pricing = product.pricing || {}
    unit_price = pricing["final_price_per_piece"] || 0
    total_price = unit_price * (quote_product.quantity || 1)
    
    summary_data = [
      ["Precio unitario:", "$ #{helpers.number_with_precision(unit_price.to_f, precision: 2)}"],
      ["Cantidad:", helpers.number_with_delimiter(quote_product.quantity || 1)],
      ["Precio total:", "$ #{helpers.number_with_precision(total_price.to_f, precision: 2)}"]
    ]
    
    summary_data.each do |label, value|
      pdf.text_box label, 
        at: [0, pdf.cursor],
        width: 120,
        size: 11,
        style: :bold
      pdf.text_box value,
        at: [120, pdf.cursor],
        size: 11
      pdf.move_down 15
    end
  end

  def add_total_costs(pdf, product)
    # Get total cost and cost per piece from the product
    pricing = product.pricing || {}
    total_cost = pricing["total_price"] || 0
    cost_per_piece = pricing["final_price_per_piece"] || 0
    
    pdf.move_down 5
    
    # Total costs section - divided into two lines, right-aligned
    # First line: Costo total
    pdf.text_box "Costo total:", 
      at: [0, pdf.cursor], 
      width: 300,
      size: 12, 
      style: :bold
    
    pdf.text_box format_currency(total_cost), 
      at: [pdf.bounds.width - 150, pdf.cursor], 
      width: 150,
      size: 12, 
      style: :bold,
      align: :right
    
    pdf.move_down 20
    
    # Second line: Costo por pieza
    pdf.text_box "Costo por pieza:", 
      at: [0, pdf.cursor], 
      width: 300,
      size: 12, 
      style: :bold
    
    pdf.text_box format_currency(cost_per_piece), 
      at: [pdf.bounds.width - 150, pdf.cursor], 
      width: 150,
      size: 12, 
      style: :bold,
      align: :right
    
    pdf.move_down 30
  end

  def add_sales_conditions(pdf, pdf_config)
    # Get sales conditions from pdf_config
    sales_conditions = [
      pdf_config&.sales_condition_1,
      pdf_config&.sales_condition_2,
      pdf_config&.sales_condition_3,
      pdf_config&.sales_condition_4
    ].compact.reject(&:blank?)
    
    if sales_conditions.any?
      pdf.move_down 10
      
      # Sales conditions title
      pdf.text "Condiciones de venta:", size: 12, style: :bold
      pdf.move_down 5
      
      # Sales conditions list
      sales_conditions.each do |condition|
        pdf.text "• #{condition}", size: 10, style: :normal
        pdf.move_down 3
      end
      
      pdf.move_down 15
    end
  end

  def add_footer(pdf, pdf_config)
    # Move to footer position (más cerca del borde)
    pdf.move_cursor_to 40
    
    # Contact information with new style - BEFORE the separator line
    begin
      contact_info = ""
      if pdf_config&.signature_name.present?
        contact_info += pdf_config.signature_name.to_s
      end
      if pdf_config&.signature_email.present?
        contact_info += " | #{pdf_config.signature_email}"
      end
      if pdf_config&.signature_phone.present?
        contact_info += " | #{pdf_config.signature_phone}"
      end
      if pdf_config&.signature_whatsapp.present?
        contact_info += " | WhatsApp: #{pdf_config.signature_whatsapp}"
      end
      
      if contact_info.strip.present?
        pdf.fill_color '42b983' # Green color
        pdf.text_box contact_info.strip, 
                     at: [0, pdf.cursor], 
                     width: pdf.bounds.width,
                     size: 9, 
                     style: :bold,
                     align: :right
        pdf.fill_color '000000' # Reset to black
      else
        pdf.fill_color '42b983' # Green color
        pdf.text_box "Equipo Cotalo | gabriel@cotalo.app", 
                     at: [0, pdf.cursor], 
                     width: pdf.bounds.width,
                     size: 9, 
                     style: :bold,
                     align: :right
        pdf.fill_color '000000' # Reset to black
      end
    rescue StandardError => e
      Rails.logger.error("Error displaying signature in PDF: #{e.message}")
      pdf.fill_color '42b983' # Green color
      pdf.text_box "Equipo Cotalo | gabriel@cotalo.app", 
                   at: [0, pdf.cursor], 
                   width: pdf.bounds.width,
                   size: 9, 
                   style: :bold,
                   align: :right
      pdf.fill_color '000000' # Reset to black
    end
    
    pdf.move_down 10
    
    # Footer with sustainability message and horizontal rule
    pdf.stroke_horizontal_rule
    pdf.move_down 10

    # PDF custom footer text (user-defined) - in black
    if pdf_config&.footer_text.present?
      pdf.fill_color '000000' # Black color
      pdf.text pdf_config.footer_text, size: 8, align: :left, style: :normal
      pdf.fill_color '000000' # Reset to black
    end
  end

  def helpers
    ActionController::Base.helpers
  end
  
  def format_currency(amount)
    return "$ 0.00" if amount.nil? || amount == 0
    "$ #{helpers.number_with_delimiter(helpers.number_with_precision(amount.to_f, precision: 2))}"
  end
  
  def month_name(month)
    {
      1 => "enero", 2 => "febrero", 3 => "marzo", 4 => "abril",
      5 => "mayo", 6 => "junio", 7 => "julio", 8 => "agosto",
      9 => "septiembre", 10 => "octubre", 11 => "noviembre", 12 => "diciembre"
    }[month]
  end
end 