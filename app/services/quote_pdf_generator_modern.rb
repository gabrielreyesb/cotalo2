class QuotePdfGeneratorModern
  attr_reader :quote

  def initialize(quote)
    @quote = quote
  end

  def generate
    pdf_config = quote.user.pdf_config
    locale = user_locale
    I18n.with_locale(locale) do
      Prawn::Document.new(page_size: "LETTER", page_layout: :landscape, margin: [20, 30, 20, 30]) do |pdf|
        pdf.font "Helvetica"
        pdf.font_size 8
        accent_color = '3aa876'
        light_gray = 'F7F7F7'
        dark_gray = '333333'

        # --- HEADER ---
        add_modern_header(pdf, pdf_config, accent_color, locale)
        pdf.move_down 6

        # --- CUSTOMER & PROJECT INFO BLOCK ---
        add_customer_project_block(pdf, light_gray, dark_gray, locale)
        pdf.move_down 18

        # --- PRODUCTS TABLE ---
        estimated_products_height = 40 + (quote.quote_products.size * 28)
        if pdf.cursor < estimated_products_height + 60
          pdf.start_new_page
        end
        pdf.bounding_box([pdf.bounds.left, pdf.cursor], width: pdf.bounds.width, keep_together: true) do
          add_modern_products_table(pdf, accent_color, light_gray, locale)
        end
        pdf.move_down 6

        # --- EXTRAS TABLE & SALES CONDITIONS LOGIC ---
        extras_rows = quote.quote_products.sum do |qp|
          product = qp.product
          extras_list = []
          extras_list += product.data["extras"] if product.data["extras"].present?
          extras_list += product.extras.map { |e| e.respond_to?(:as_json) ? e.as_json : e } if product.extras.present?
          extras_list += product.data["product_extras"] if product.data["product_extras"].present?
          extras_list.any? ? (extras_list.size + 1) : 0
        end
        estimated_extras_height = 20 + (extras_rows * 16)
        estimated_conditions_height = 60
        footer_buffer = 60
        remaining_space = pdf.cursor

        if remaining_space >= estimated_extras_height + footer_buffer
          pdf.bounding_box([pdf.bounds.left, pdf.cursor], width: pdf.bounds.width, keep_together: true) do
            pdf.text I18n.t('quotes.pdf.extras'), size: 11, style: :bold, color: '000000'
            pdf.move_down 4
            add_modern_extras_table(pdf, accent_color, light_gray, locale)
          end
          pdf.move_down 6
          if pdf.cursor < estimated_conditions_height + footer_buffer
            pdf.start_new_page
          end
          add_modern_sales_conditions(pdf, pdf_config, light_gray, dark_gray, locale)
          pdf.move_down 18
        else
          pdf.start_new_page
          pdf.bounding_box([pdf.bounds.left, pdf.cursor], width: pdf.bounds.width, keep_together: true) do
            pdf.text I18n.t('quotes.pdf.extras'), size: 11, style: :bold, color: '000000'
            pdf.move_down 4
            add_modern_extras_table(pdf, accent_color, light_gray, locale)
          end
          pdf.move_down 6
          add_modern_sales_conditions(pdf, pdf_config, light_gray, dark_gray, locale)
          pdf.move_down 18
        end

        pdf.repeat(:all) do
          pdf.bounding_box([pdf.bounds.left, pdf.bounds.bottom + 40], width: pdf.bounds.width, height: 40) do
            pdf.fill_color accent_color
            pdf.fill_rectangle [0, 40], pdf.bounds.width, 40
            pdf.fill_color 'FFFFFF'
            msg = pdf_config&.footer_text.to_s.strip.presence || I18n.t('quotes.pdf.sustainable_message')
            pdf.text_box msg, at: [10, 28], size: 9, align: :left, valign: :center
            begin
              pdf.image "#{Rails.root}/public/images/Bosques.png", width: 24, at: [pdf.bounds.right - 80, 28]
            rescue; end
            begin
              pdf.image "#{Rails.root}/public/images/FDA.jpg", width: 24, at: [pdf.bounds.right - 50, 28]
            rescue; end
            begin
              pdf.image "#{Rails.root}/public/images/qr-code.png", width: 20, at: [pdf.bounds.right - 20, 28]
            rescue; end
          end
          signature = [
            pdf_config&.signature_name.to_s.strip,
            pdf_config&.signature_email.to_s.strip,
            pdf_config&.signature_phone.to_s.strip,
            (pdf_config&.signature_whatsapp.present? ? I18n.t('quotes.pdf.whatsapp_label', number: pdf_config.signature_whatsapp.to_s.strip) : nil)
          ].reject(&:blank?)
          if signature.any?
            pdf.bounding_box([0, pdf.bounds.bottom + 60], width: pdf.bounds.width, height: 20) do
              pdf.text signature.join("   |   "), size: 9, style: :bold, align: :right, color: accent_color
            end
          end
        end
      end.render
    end
  end

  # Helper to get the user's locale or fallback
  def user_locale
    I18n.locale
  end

  def add_modern_header(pdf, pdf_config, accent_color, locale)
    logo_url = pdf_config&.logo_url
    I18n.with_locale(locale) do
      pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width, height: 60) do
        if logo_url.present?
          begin
            logo_tempfile = Down.download(logo_url)
            pdf.image logo_tempfile.path, width: 90, at: [0, pdf.bounds.top - 5]
            logo_tempfile.close
            logo_tempfile.unlink
          rescue
            pdf.fill_color accent_color
            pdf.text_box I18n.t('quotes.pdf.logo_placeholder'), at: [0, pdf.bounds.top - 5], size: 20, style: :bold
            pdf.fill_color '000000'
          end
        else
          pdf.fill_color accent_color
          pdf.text_box I18n.t('quotes.pdf.logo_placeholder'), at: [0, pdf.bounds.top - 5], size: 20, style: :bold
          pdf.fill_color '000000'
        end
        pdf.text_box I18n.t('quotes.pdf.header'), at: [pdf.bounds.right - 200, pdf.bounds.top], width: 200, align: :right, size: 16, style: :bold, color: accent_color
        pdf.text_box "#{quote.quote_number}", at: [pdf.bounds.right - 200, pdf.bounds.top - 22], width: 200, align: :right, size: 13, style: :bold
        pdf.text_box I18n.t('quotes.pdf.date_line', date: I18n.l(quote.created_at, format: :long)), at: [pdf.bounds.right - 200, pdf.bounds.top - 40], width: 200, align: :right, size: 9, color: '888888'
      end
      pdf.stroke_horizontal_rule
    end
  end

  def add_customer_project_block(pdf, bg_color, text_color, locale)
    I18n.with_locale(locale) do
      pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width, height: 60) do
        pdf.fill_color bg_color
        pdf.fill_rectangle [0, pdf.cursor], pdf.bounds.width, 60
        pdf.fill_color text_color
        data = [
          [I18n.t('quotes.pdf.customer'), quote.customer_name, I18n.t('quotes.pdf.organization'), quote.organization || I18n.t('quotes.pdf.not_specified')],
          [I18n.t('quotes.pdf.email'), quote.email || I18n.t('quotes.pdf.not_specified'), I18n.t('quotes.pdf.telephone'), quote.telephone || I18n.t('quotes.pdf.not_specified')],
          [I18n.t('quotes.pdf.project'), quote.project_name, "", ""]
        ]
        pdf.move_down 10
        pdf.table(data, cell_style: { borders: [], padding: [2, 6, 2, 0], size: 10, text_color: text_color }, width: pdf.bounds.width)
      end
    end
  end

  def add_modern_products_table(pdf, accent_color, bg_color, locale)
    I18n.with_locale(locale) do
      header = [
        I18n.t('quotes.pdf.date'),
        I18n.t('quotes.pdf.product'),
        I18n.t('quotes.pdf.measurements'),
        I18n.t('quotes.pdf.resistance'),
        I18n.t('quotes.pdf.materials'),
        I18n.t('quotes.pdf.processes'),
        I18n.t('quotes.pdf.quantity'),
        I18n.t('quotes.pdf.unit_price')
      ]
      rows = [header]
      quote.quote_products.each do |qp|
        product = qp.product
        info = product.general_info
        measures = if info["inner_measurements"].is_a?(Hash)
          %w[length width height].map { |k| info["inner_measurements"][k] }.compact.join(" x ")
        else
          info["inner_measurements"].to_s
        end
        materials = (product.materials || []).map { |m| m["client_description"] || m["name"] }.compact
        materials_text = materials.any? ? materials.map { |m| "• #{m}" }.join("\n") : "-"
        resistances = (product.materials || []).map { |m| m["resistance"] }.compact
        resistance_text = resistances.any? ? resistances.join(", ") : "-"
        processes = (product.processes || []).map { |p| p["description"] }.compact
        processes_text = processes.any? ? processes.map { |p| "• #{p}" }.join("\n") : "-"
        quantity = info["quantity"] || qp.quantity
        unit_price = product.pricing.try(:[], "final_price_per_piece") || 0
        rows << [
          qp.created_at.strftime("%d/%m/%Y"),
          product.description,
          measures,
          resistance_text,
          materials_text,
          processes_text,
          helpers.number_with_delimiter(quantity),
          "#{I18n.t('quotes.pdf.currency_symbol')} #{helpers.number_with_precision(unit_price.to_f, precision: 2)}"
        ]
      end
      pdf.bounding_box([pdf.bounds.left, pdf.cursor], width: pdf.bounds.width, keep_together: true) do
        pdf.table(rows, header: true, cell_style: { size: 9, inline_format: true, padding: [6, 4, 6, 4] }, column_widths: { 0 => 60, 1 => 130, 2 => 95, 3 => 80, 4 => 95, 5 => 130, 6 => 75, 7 => 65 }) do |t|
          t.row(0).font_style = :bold
          t.row(0).background_color = accent_color
          t.row(0).text_color = 'FFFFFF'
          t.row(0).align = :center
          t.column(0..7).align = :center
          t.column(1).align = :left
          t.column(4).align = :left
          t.column(5).align = :left
          t.cells.borders = [:left, :right, :top, :bottom]
          t.cells.border_width = 0.5
          t.cells.border_color = "CCCCCC"
          (1...rows.length).each do |i|
            t.row(i).background_color = i.even? ? bg_color : 'FFFFFF'
          end
        end
      end
      pdf.move_down 5
      pdf.text I18n.t('quotes.pdf.tax_note'), align: :right, size: 9, style: :bold, color: accent_color
    end
  end

  def add_modern_extras_table(pdf, accent_color, bg_color, locale)
    I18n.with_locale(locale) do
      extras = []
      quote.quote_products.each do |qp|
        product = qp.product
        extras_list = []
        if product.data["extras"].present?
          extras_list += product.data["extras"]
        end
        if product.extras.present?
          extras_list += product.extras.map { |e| e.respond_to?(:as_json) ? e.as_json : e }
        end
        if product.data["product_extras"].present?
          extras_list += product.data["product_extras"]
        end
        extras_by_name = {}
        extras_list.each do |extra|
          name = extra["name"] || extra["description"]
          next unless name.present?
          extras_by_name[name] = extra
        end
        if extras_by_name.any?
          extras << [{ content: product.description.to_s, colspan: 3, font_style: :bold, background_color: accent_color, text_color: 'FFFFFF' }]
          extras_by_name.each_value do |extra|
            price = extra["price"] || extra["unit_price"] || 0
            quantity = extra["quantity"] || 1
            total = price.to_f * quantity
            price_display = quantity > 1 ? "#{I18n.t('quotes.pdf.currency_symbol')} #{helpers.number_with_delimiter(helpers.number_with_precision(total, precision: 2))} (#{quantity} x #{helpers.number_with_delimiter(helpers.number_with_precision(price.to_f, precision: 2))})" : "#{I18n.t('quotes.pdf.currency_symbol')} #{helpers.number_with_delimiter(helpers.number_with_precision(price.to_f, precision: 2))}"
            extras << [extra["name"] || extra["description"], extra["description"] || "-", price_display]
          end
        end
      end
      if extras.any?
        pdf.bounding_box([pdf.bounds.left, pdf.cursor], width: pdf.bounds.width, keep_together: true) do
          pdf.table(extras, cell_style: { size: 9, padding: [6, 4, 6, 4], borders: [:left, :right, :top, :bottom], border_width: 0.5, border_color: "CCCCCC" }, width: pdf.bounds.width) do |t|
            t.cells.align = :left
            t.column(2).align = :right
            extras.each_with_index do |row, i|
              if row[0].is_a?(Hash)
                t.row(i).font_style = :bold
                t.row(i).background_color = accent_color
                t.row(i).text_color = 'FFFFFF'
              end
            end
            (1...extras.length).each do |i|
              unless extras[i][0].is_a?(Hash)
                t.row(i).background_color = i.even? ? bg_color : 'FFFFFF'
              end
            end
          end
        end
      end
    end
  end

  def add_modern_sales_conditions(pdf, pdf_config, bg_color, text_color, locale)
    I18n.with_locale(locale) do
      sales_conditions = [
        pdf_config&.sales_condition_1,
        pdf_config&.sales_condition_2,
        pdf_config&.sales_condition_3,
        pdf_config&.sales_condition_4
      ].map { |c| c.to_s.strip }.reject(&:blank?)
      if sales_conditions.any?
        pdf.move_down 5
        pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width, height: 50) do
          pdf.fill_color bg_color
          pdf.fill_rectangle [0, pdf.cursor], pdf.bounds.width, 50
          pdf.fill_color text_color
          pdf.move_down 10
          pdf.text I18n.t('quotes.pdf.sales_conditions'), size: 10, style: :bold
          pdf.move_down 4
          conditions_text = sales_conditions.join('. ') + '.'
          pdf.text conditions_text, size: 9, width: pdf.bounds.width - 40
        end
      end
    end
  end

  def helpers
    ActionController::Base.helpers
  end
end 