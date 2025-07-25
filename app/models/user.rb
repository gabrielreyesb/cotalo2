class User < ApplicationRecord
  include StripeSubscription

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable

  has_many :materials, dependent: :destroy
  has_many :manufacturing_processes, dependent: :destroy
  has_many :extras, dependent: :destroy
  has_many :app_configs, dependent: :destroy
  has_one :pdf_config, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :quotes, dependent: :destroy
  has_many :price_margins, dependent: :destroy
  has_many :suggestions, dependent: :destroy
  has_many :customers, dependent: :destroy

  after_create :setup_initial_data
  after_create :send_admin_notification
  after_create :send_welcome_email

  # Subscription status constants
  SUBSCRIPTION_STATUS_TRIAL = 'trial'
  SUBSCRIPTION_STATUS_ACTIVE = 'active'
  SUBSCRIPTION_STATUS_PAST_DUE = 'past_due'
  SUBSCRIPTION_STATUS_CANCELLED = 'cancelled'
  SUBSCRIPTION_STATUS_EXPIRED = 'expired'

  # Trial period in days
  TRIAL_PERIOD_DAYS = 14

  # Set default subscription status for new users
  after_initialize :set_default_subscription_status, if: :new_record?

  def admin?
    admin
  end

  def disabled?
    disabled
  end

  def active_for_authentication?
    return true if admin? # Allow admins to always be active
    super && !disabled? && subscription_active?
  end

  def inactive_message
    if disabled?
      :account_disabled
    else
      super
    end
  end

  # Helper methods to access configuration values
  
  # Get a configuration value
  def get_config(key)
    AppConfig.get(self, key)
  end
  
  # Set a configuration value
  def set_config(key, value, value_type = AppConfig::TEXT)
    AppConfig.set(self, key, value, value_type)
  end
  
  # Get waste percentage (default 0) – returns the numeric value as stored (e.g. 10 for 10%)
  def waste_percentage
    get_config(AppConfig::WASTE_PERCENTAGE) || 0
  end
  
  # (Optional) Get waste percentage as a decimal (e.g. 0.1 for 10%)
  def waste_percentage_decimal
    (get_config(AppConfig::WASTE_PERCENTAGE) || 0) / 100.0
  end
  
  # Get width margin (default 0)
  def width_margin
    get_config(AppConfig::WIDTH_MARGIN) || 0
  end
  
  # Get length margin (default 0)
  def length_margin
    get_config(AppConfig::LENGTH_MARGIN) || 0
  end

  # Subscription-related methods
  def trial?
    subscription_status == SUBSCRIPTION_STATUS_TRIAL
  end

  def active_subscription?
    subscription_status == SUBSCRIPTION_STATUS_ACTIVE
  end

  def subscription_active?
    # Temporarily disabled - all users have unlimited access
    true
  end

  def setup_trial_period
    return unless trial_ends_at.nil?
    update(
      trial_ends_at: TRIAL_PERIOD_DAYS.days.from_now,
      subscription_status: SUBSCRIPTION_STATUS_TRIAL
    )
  end

  def example_product
    products.find_by(description: "Caja plegadiza cosmética – cartulina caple 12 pts")
  end

  def has_real_products?
    # Count products excluding the example product
    real_products_count = products.where.not(description: "Caja plegadiza cosmética – cartulina caple 12 pts").count
    real_products_count > 0
  end

  def should_show_reminder?
    # Show reminder if:
    # 1. User has no real products
    # 2. Account is older than 3 days
    # 3. Reminder block is not closed
    return false if has_real_products?
    return false if block_closed?('reminder')
    return false if created_at > 3.days.ago
    
    true
  end

  def dashboard_preferences
    JSON.parse(self[:dashboard_preferences] || '{}')
  rescue JSON::ParserError
    {}
  end

  def dashboard_preferences=(preferences)
    self[:dashboard_preferences] = preferences.to_json
  end

  def block_closed?(block_name)
    dashboard_preferences[block_name.to_s] == true
  end

  def close_block(block_name)
    prefs = dashboard_preferences
    prefs[block_name.to_s] = true
    self.dashboard_preferences = prefs
    save
  end

  # Methods for admin dashboard activity tracking
  def products_count
    self[:products_count] || products.count
  end

  def quotes_count
    self[:quotes_count] || quotes.count
  end

  def has_activity?
    products_count > 0 || quotes_count > 0
  end

  def activity_summary
    {
      products: products_count,
      quotes: quotes_count,
      has_activity: has_activity?
    }
  end

  private

  def setup_initial_data
    setup_trial_period
    begin
      Rails.logger.info "[setup_initial_data] Creating or finding units..."
      mt2_unit = Unit.find_or_create_by!(name: 'mt2', abbreviation: 'm²')
      pieza_unit = Unit.find_or_create_by!(name: 'pieza', abbreviation: 'pieza')
      pliego_unit = Unit.find_or_create_by!(name: 'pliego', abbreviation: 'pliego')
      kg_unit = Unit.find_or_create_by!(name: 'kg', abbreviation: 'kg')
      # millar_unit removed

      Rails.logger.info "[setup_initial_data] Setting default app configs..."
      set_config(AppConfig::WASTE_PERCENTAGE, 5, AppConfig::NUMERIC)
      set_config(AppConfig::WIDTH_MARGIN, 2, AppConfig::NUMERIC)
      set_config(AppConfig::LENGTH_MARGIN, 2, AppConfig::NUMERIC)
      set_config('customer_name', 'Cotalo')
      set_config('company_name', 'Cotalo')
      set_config(AppConfig::THEME, 'dark')

      Rails.logger.info "[setup_initial_data] Creating demo materials..."
      materials.create!([
        { description: 'Cartulina caple sulfatada 12 pts', client_description: 'Cartulina caple sulfatada 12 pts', price: 9.5, unit: mt2_unit, ancho: 100, largo: 100 },
        { description: 'Cartulina caple sulfatada 14 pts', client_description: 'Cartulina caple sulfatada 14 pts', price: 11, unit: mt2_unit, ancho: 100, largo: 100 },
        { description: 'Papel couché brillante 150 g/m²', client_description: 'Papel couché brillante 150 g/m²', price: 7, unit: mt2_unit, ancho: 100, largo: 100 },
        { description: 'Cartón microcorrugado blanco', client_description: 'Cartón microcorrugado blanco', price: 17, unit: kg_unit, ancho: 100, largo: 100 },
        { description: 'Cartón gris (Backing)', client_description: 'Cartón gris (Backing)', price: 13, unit: kg_unit, ancho: 100, largo: 100 },
        { description: 'Papel couché mate 170 g/m²', client_description: 'Papel de acabado elegante para folletos y trípticos', price: 7.5, unit: mt2_unit, ancho: 100, largo: 100 },
        { description: 'Papel bond 90 g/m²', client_description: 'Papel común para hojas membretadas y volantes simples', price: 5.0, unit: mt2_unit, ancho: 100, largo: 100 },
        { description: 'Cartulina opalina 250 g/m²', client_description: 'Papel rígido blanco para tarjetas, folders, portadas', price: 9.5, unit: mt2_unit, ancho: 100, largo: 100 },
        { description: 'Papel ecológico kraft 180 g/m²', client_description: 'Para proyectos con estética sustentable', price: 8.0, unit: mt2_unit, ancho: 100, largo: 100 },
        { description: 'PVC sintético 300 micras', client_description: 'Material plástico para menús, credenciales', price: 12.0, unit: mt2_unit, ancho: 100, largo: 100 },
        { description: 'Acetato transparente', client_description: 'Usado en cubiertas o efectos gráficos', price: 10.0, unit: mt2_unit, ancho: 100, largo: 100 },
        { description: 'Etiqueta adhesiva blanca 80 g/m²', client_description: 'Para stickers o etiquetas impresas', price: 6.5, unit: mt2_unit, ancho: 100, largo: 100 },
        { description: 'Papel reciclado 110 g/m²', client_description: 'Papel texturizado para papelería con identidad ecológica', price: 6.0, unit: mt2_unit, ancho: 100, largo: 100 }
      ])

      Rails.logger.info "[setup_initial_data] Creating demo manufacturing processes..."
      manufacturing_processes.create!([
        { name: 'Impresión offset 4 tintas (CMYK)', description: 'Impresión a color estándar en cartulina caple, ideal para tirajes medianos y altos.', cost: 4.00, unit: mt2_unit },
        { name: 'Impresión Pantone (1 tinta)', description: 'Impresión con tinta directa Pantone para colores especiales o logotipos.', cost: 2.50, unit: mt2_unit },
        { name: 'Barniz UV spot', description: 'Aplicación localizada de barniz brillante para resaltar elementos gráficos.', cost: 3.20, unit: mt2_unit },
        { name: 'Laminado brillante', description: 'Película protectora de acabado brillante para superficies impresas.', cost: 2.80, unit: mt2_unit },
        { name: 'Laminado mate', description: 'Película protectora de acabado mate, ideal para empaques premium.', cost: 3.00, unit: mt2_unit },
        { name: 'Hot stamping', description: 'Aplicación de foil metálico (oro, plata, etc.) para efectos decorativos de alto impacto.', cost: 6.00, unit: mt2_unit },
        { name: 'Relieve seco (embossing)', description: 'Técnica de realce sin tinta que genera volumen o textura sobre el material.', cost: 5.00, unit: mt2_unit },
        { name: 'Troquelado', description: 'Corte especializado con troquel metálico para dar forma a la caja.', cost: 300.00 / 1000.0, unit: pieza_unit },
        { name: 'Hendido y corte', description: 'Preparación de dobleces con corte parcial para facilitar el armado.', cost: 180.00 / 1000.0, unit: pieza_unit },
        { name: 'Pegado automático', description: 'Aplicación automática de adhesivo para el ensamblado de cajas plegadizas.', cost: 250.00 / 1000.0, unit: pieza_unit },
        { name: 'Rebase o registro de color', description: 'Ajuste de colores entre pliegos para mantener consistencia cromática', cost: 0.20, unit: pieza_unit },
        { name: 'Inserción manual', description: 'Colocación de elementos sueltos (tarjetas, hojas, encartes) dentro de folders o revistas', cost: 0.30, unit: pieza_unit },
        { name: 'Encuadernado con grapa (caballo)', description: 'Grapado central típico en folletos, revistas pequeñas o catálogos', cost: 0.35, unit: pieza_unit },
        { name: 'Encuadernado hotmelt (pegado)', description: 'Pegado lateral con termofusible (hotmelt) para libretas o catálogos', cost: 0.50, unit: pieza_unit },
        { name: 'Fresado para encuadernado', description: 'Preparación del lomo para recibir pegamento o encuadernación', cost: 0.40, unit: pieza_unit },
        { name: 'Perforado múltiple', description: 'Para anillas o encuadernaciones tipo argolla', cost: 0.20, unit: pieza_unit },
        { name: 'Plastificado en frío', description: 'Alternativa al laminado para tirajes cortos o materiales sensibles al calor', cost: 3.50, unit: mt2_unit },
        { name: 'Numeración variable', description: 'Impresión digital de datos variables, como folios o códigos', cost: 0.40, unit: pieza_unit },
        { name: 'Barniz mate total', description: 'Recubrimiento general mate para folders, portadas o papelería de lujo', cost: 2.80, unit: mt2_unit },
        { name: 'Contracolado', description: 'Unión de capas de papel/cartulina para dar mayor rigidez o acabado especial', cost: 4.20, unit: mt2_unit }
      ])

      Rails.logger.info "[setup_initial_data] Creating demo extras..."
      extras.create!([
        { name: 'Fabricación de troquel', description: 'Costo único por fabricación del troquel metálico con la forma de la caja. Aplica solo si no se tiene uno previo.', cost: 1800, unit: pieza_unit },
        { name: 'Fabricación de placa offset (por tinta)', description: 'Placa de aluminio necesaria para cada tinta en impresión offset. Se requiere una por tinta utilizada.', cost: 250, unit: pieza_unit },
        { name: 'Calibración de máquina impresora', description: 'Tiempo y desperdicio asociados al arranque y ajuste de la impresora para un trabajo nuevo.', cost: 400, unit: pieza_unit },
        { name: 'Calibración de troqueladora', description: 'Ajuste de la troqueladora para que corte con precisión. Costo por proyecto.', cost: 350, unit: pieza_unit },
        { name: 'Desarrollo de muestra física (mockup)', description: 'Creación de una muestra previa a producción para aprobación del cliente.', cost: 300, unit: pieza_unit },
        { name: 'Diseño gráfico del empaque', description: 'Diseño profesional del arte final del empaque. Puede no aplicar si el cliente ya proporciona arte.', cost: 700, unit: pieza_unit },
        { name: 'Supervisión de producción', description: 'Costo por seguimiento personalizado en piso de producción para garantizar calidad.', cost: 250, unit: pieza_unit },
        { name: 'Diseño gráfico editorial', description: 'Maquetación de revistas, catálogos o folletos con múltiples páginas', cost: 600.00, unit: pieza_unit },
        { name: 'Ajuste de archivos para impresión', description: 'Conversión, corrección de perfiles de color, sangrados, tipografías', cost: 150.00, unit: pieza_unit },
        { name: 'Prueba de color digital (matchprint)', description: 'Simulación de impresión en digital para aprobación del cliente', cost: 250.00, unit: pieza_unit },
        { name: 'Digitalización de logotipos o escaneos', description: 'Conversión de materiales físicos o imágenes a formato editable', cost: 120.00, unit: pieza_unit },
        { name: 'Envío de prueba física al cliente', description: 'Envío de mockup o impresión de muestra con guía', cost: 180.00, unit: pieza_unit },
        { name: 'Supervisión editorial', description: 'Validación del contenido antes de impresión (tipografía, errores, coherencia)', cost: 200.00, unit: pieza_unit },
        { name: 'Gestión de derechos de imagen o stock', description: 'Compra de fotografías, ilustraciones o licencias necesarias', cost: 200.00, unit: pieza_unit },
        { name: 'Empaque personalizado para entrega', description: 'Caja, bolsa o folder especial para presentación del pedido final', cost: 50.00, unit: pieza_unit }
      ])

      Rails.logger.info "[setup_initial_data] Creating demo price margins..."
      price_margins.create!([
        { min_price: 0, max_price: 5000, margin_percentage: 10 },
        { min_price: 5001, max_price: 50000, margin_percentage: 15 },
        { min_price: 50001, max_price: 200000, margin_percentage: 25 }
      ])

      Rails.logger.info "[setup_initial_data] Creating demo product..."
      # Get the created demo data for the cosmetic box
      cartulina_material = materials.find_by(description: 'Cartulina caple sulfatada 12 pts')
      offset_process = manufacturing_processes.find_by(name: 'Impresión offset 4 tintas (CMYK)')
      barniz_process = manufacturing_processes.find_by(name: 'Barniz UV spot')
      troquelado_process = manufacturing_processes.find_by(name: 'Troquelado')
      hendido_process = manufacturing_processes.find_by(name: 'Hendido y corte')
      pegado_process = manufacturing_processes.find_by(name: 'Pegado automático')
      
      # Get the required extras
      troquel_extra = extras.find_by(name: 'Fabricación de troquel')
      placa_extra = extras.find_by(name: 'Fabricación de placa offset (por tinta)')
      calibracion_impresora_extra = extras.find_by(name: 'Calibración de máquina impresora')
      calibracion_troqueladora_extra = extras.find_by(name: 'Calibración de troqueladora')
      muestra_extra = extras.find_by(name: 'Desarrollo de muestra física (mockup)')

      # Calculate material area for 1000 pieces (32cm x 22cm = 0.32m x 0.22m = 0.0704 m² per piece)
      # Assuming 6 pieces per sheet: 1000 pieces / 6 = 167 sheets needed
      # Total area: 167 sheets * 0.0704 m² = 11.76 m²
      area_per_piece = 0.32 * 0.22  # 0.0704 m²
      pieces_per_sheet = 6
      total_sheets = (1000.0 / pieces_per_sheet).ceil  # 167 sheets
      total_area = total_sheets * area_per_piece  # 11.76 m²

      # Create the cosmetic box product
      product_quantity = 1000
      test_product = products.create!(
        description: "Caja plegadiza cosmética – cartulina caple 12 pts",
        data: {
          general_info: {
            width: 32,
            length: 22,
            inner_measurements: nil,
            quantity: product_quantity,
            comments: "Caja plegadiza cosmética – 4 tintas + barniz UV"
          },
          materials: [
            {
              material_id: cartulina_material.id,
              materialInstanceId: "#{cartulina_material.id}_1",
              materialInstanceNumber: 1,
              displayName: "#{cartulina_material.description} (1)",
              description: cartulina_material.description,
              client_description: cartulina_material.client_description,
              resistance: cartulina_material.resistance,
              price: (cartulina_material.price || 0).to_f,
              unit: {
                id: cartulina_material.unit.id,
                name: cartulina_material.unit.name,
                abbreviation: cartulina_material.unit.abbreviation
              },
              ancho: (cartulina_material.ancho || 0).to_f,
              largo: (cartulina_material.largo || 0).to_f,
              quantity: product_quantity,
              piecesPerMaterial: pieces_per_sheet,
              totalSheets: total_sheets,
              totalSquareMeters: total_area,
              totalPrice: total_area * cartulina_material.price,
              subtotal_price: total_area * cartulina_material.price,
              comments: "Cartulina caple sulfatada 12 pts para caja cosmética"
            }
          ],
          processes: [
            {
              process_id: offset_process.id,
              description: offset_process.name,
              unit: offset_process.unit.abbreviation,
              unitPrice: offset_process.cost,
              materialId: "#{cartulina_material.id}_1",
              materialDescription: cartulina_material.description,
              price: offset_process.cost * total_area,
              veces: 1,
              comments: "Impresión offset 4 tintas CMYK para caja cosmética"
            },
            {
              process_id: barniz_process.id,
              description: barniz_process.name,
              unit: barniz_process.unit.abbreviation,
              unitPrice: barniz_process.cost,
              materialId: "#{cartulina_material.id}_1",
              materialDescription: cartulina_material.description,
              price: barniz_process.cost * total_area,
              veces: 1,
              comments: "Barniz UV spot para acabado premium"
            },
            {
              process_id: troquelado_process.id,
              description: troquelado_process.name,
              unit: troquelado_process.unit.abbreviation,
              unitPrice: troquelado_process.cost,
              materialId: "#{cartulina_material.id}_1",
              materialDescription: cartulina_material.description,
              price: troquelado_process.unit.abbreviation == 'pieza' ? troquelado_process.cost * product_quantity * 1 : troquelado_process.cost * 1,
              veces: 1,
              comments: "Troquelado para forma de caja cosmética"
            },
            {
              process_id: hendido_process.id,
              description: hendido_process.name,
              unit: hendido_process.unit.abbreviation,
              unitPrice: hendido_process.cost,
              materialId: "#{cartulina_material.id}_1",
              materialDescription: cartulina_material.description,
              price: hendido_process.unit.abbreviation == 'pieza' ? hendido_process.cost * product_quantity * 1 : hendido_process.cost * 1,
              veces: 1,
              comments: "Hendido y corte para dobleces"
            },
            {
              process_id: pegado_process.id,
              description: pegado_process.name,
              unit: pegado_process.unit.abbreviation,
              unitPrice: pegado_process.cost,
              materialId: "#{cartulina_material.id}_1",
              materialDescription: cartulina_material.description,
              price: pegado_process.unit.abbreviation == 'pieza' ? pegado_process.cost * product_quantity * 1 : pegado_process.cost * 1,
              veces: 1,
              comments: "Pegado automático para ensamblado"
            }
          ],
          extras: [
            {
              extra_id: troquel_extra.id,
              name: troquel_extra.name,
              description: troquel_extra.description,
              unit_price: troquel_extra.cost.to_f,
              quantity: 1,
              total: troquel_extra.cost.to_f * 1,
              comments: "Fabricación de troquel para caja cosmética"
            },
            {
              extra_id: placa_extra.id,
              name: placa_extra.name,
              description: placa_extra.description,
              unit_price: placa_extra.cost.to_f,
              quantity: 4,
              total: placa_extra.cost.to_f * 4,
              comments: "4 placas offset para CMYK"
            },
            {
              extra_id: calibracion_impresora_extra.id,
              name: calibracion_impresora_extra.name,
              description: calibracion_impresora_extra.description,
              unit_price: calibracion_impresora_extra.cost.to_f,
              quantity: 1,
              total: calibracion_impresora_extra.cost.to_f * 1,
              comments: "Calibración de máquina impresora"
            },
            {
              extra_id: calibracion_troqueladora_extra.id,
              name: calibracion_troqueladora_extra.name,
              description: calibracion_troqueladora_extra.description,
              unit_price: calibracion_troqueladora_extra.cost.to_f,
              quantity: 1,
              total: calibracion_troqueladora_extra.cost.to_f * 1,
              comments: "Calibración de troqueladora"
            },
            {
              extra_id: muestra_extra.id,
              name: muestra_extra.name,
              description: muestra_extra.description,
              unit_price: muestra_extra.cost.to_f,
              quantity: 1,
              total: muestra_extra.cost.to_f * 1,
              comments: "Desarrollo de muestra física"
            }
          ],
          pricing: {
            materials_cost: total_area * cartulina_material.price,
            processes_cost: (offset_process.cost * total_area) + (barniz_process.cost * total_area) + troquelado_process.cost + hendido_process.cost + pegado_process.cost,
            extras_cost: troquel_extra.cost + (placa_extra.cost * 4) + calibracion_impresora_extra.cost + calibracion_troqueladora_extra.cost + muestra_extra.cost,
            subtotal: 0,  # Will be calculated
            waste_percentage: 5,
            waste_value: 0,  # Will be calculated
            price_per_piece_before_margin: 0,  # Will be calculated
            margin_percentage: 10,
            margin_value: 0,  # Will be calculated
            total_price: 0,  # Will be calculated
            final_price_per_piece: 0  # Will be calculated
          }
        }
      )

      # Calculate and save product totals so the price is not zero in the example quote
      test_product.calculate_totals
      test_product.save!
      test_product.reload

      Rails.logger.info "[setup_initial_data] Demo data creation complete."
      
      # Create a test quote using the test product
      Rails.logger.info "[setup_initial_data] Creating demo quote..."
      test_quote = quotes.create!(
        project_name: "Caja plegadiza para producto cosmético premium",
        customer_name: "María González",
        organization: "BeautyLab Cosméticos",
        email: "maria.gonzalez@beautylab.com",
        telephone: "+52 55 1234 5678",
        comments: "Cotización para empaque de producto cosmético premium. Requerimos acabado de alta calidad con barniz UV y troquelado especializado.",
        data: Quote.default_data
      )
      
      # Add the test product to the quote
      test_quote.quote_products.create!(
        product: test_product,
        quantity: 1
      )
      
      # Calculate totals for the quote
      test_quote.calculate_totals
      
      # Add product details to the quote's data for frontend display
      test_quote.data['products'] = [
        {
          product_id: test_product.id,
          description: test_product.description,
          quantity: 50,
          unit_price: test_product.data['pricing']['final_price_per_piece'],
          total_price: test_product.data['pricing']['final_price_per_piece'].to_f * 50
        }
      ]
      test_quote.save!
      
      Rails.logger.info "[setup_initial_data] Demo quote created: #{test_quote.quote_number}"
      
      # Create example customer
      Rails.logger.info "[setup_initial_data] Creating example customer..."
      customers.create!(
        name: "María González",
        email: "maria.gonzalez@beautylab.com",
        phone: "+52 55 1234 5678",
        company: "BeautyLab Cosméticos",
        address: "Av. Insurgentes Sur 1234, Col. Del Valle, Ciudad de México, CDMX",
        notes: "Cliente premium especializado en productos cosméticos de alta gama. Requiere acabados especiales y materiales sustentables."
      )
      
      Rails.logger.info "[setup_initial_data] Example customer created."
      
      # Create PDF configuration
      Rails.logger.info "[setup_initial_data] Creating PDF configuration..."
      create_pdf_config!(
        logo_url: ActionController::Base.helpers.asset_path('Cotalo_logo.png'),
        footer_text: "Creamos productos de alta calidad con materiales y procesos sustentables",
        signature_name: "Ing. Carlos Mendoza",
        signature_email: "carlos.mendoza@cotalo.com",
        signature_phone: "+52 55 9876 5432",
        signature_whatsapp: "+52 55 9876 5432",
        sales_condition_1: "Pregunta por nuestros planes de financiamiento",
        sales_condition_2: "Precios válidos por 30 días",
        sales_condition_3: "Tiempo de entrega: 15-20 días hábiles",
        sales_condition_4: "Pago: 50% al confirmar, 50% antes de entrega"
      )
      
      Rails.logger.info "[setup_initial_data] PDF configuration created."

      # Create the example product: Folder corporativo institucional
      folder_quantity = 2500
      folder_width = 33
      folder_length = 66
      caple_14 = materials.find_by(description: 'Cartulina caple sulfatada 14 pts')
      couche_150 = materials.find_by(description: 'Papel couché brillante 150 g/m²')
      offset_proc = manufacturing_processes.find_by(name: 'Impresión offset 4 tintas (CMYK)')
      barniz_proc = manufacturing_processes.find_by(name: 'Barniz UV spot')
      laminado_proc = manufacturing_processes.find_by(name: 'Laminado mate')
      hendido_proc = manufacturing_processes.find_by(name: 'Hendido y corte')
      diseno_extra = extras.find_by(name: 'Diseño gráfico del empaque')
      placa_extra = extras.find_by(name: 'Fabricación de placa offset (por tinta)')
      mockup_extra = extras.find_by(name: 'Desarrollo de muestra física (mockup)')
      supervision_extra = extras.find_by(name: 'Supervisión de producción')
      envio_prueba_extra = extras.find_by(name: 'Envío de prueba física al cliente')

      # Calculate area per piece, pieces per sheet, total sheets, total area as in the original example
      folder_area_per_piece = folder_width * folder_length / 100.0 / 100.0 # m²
      folder_pieces_per_sheet = 1 # For folders, assume 1 per sheet unless you have a better value
      folder_total_sheets = (folder_quantity.to_f / folder_pieces_per_sheet).ceil
      folder_total_area = folder_total_sheets * folder_area_per_piece

      folder_product = products.create!(
        description: "Folder corporativo institucional – Folder de presentación tamaño carta con bolsillos interiores, impresión a color y acabado laminado.",
        data: {
          general_info: {
            width: folder_width,
            length: folder_length,
            inner_measurements: nil,
            quantity: folder_quantity,
            comments: "Folder de presentación tamaño carta con bolsillos interiores, impresión a color y acabado laminado."
          },
          materials: [
            {
              material_id: caple_14&.id,
              materialInstanceId: caple_14&.id ? "#{caple_14.id}_1" : nil,
              materialInstanceNumber: 1,
              displayName: caple_14&.description ? "#{caple_14.description} (1)" : nil,
              description: caple_14&.description,
              client_description: caple_14&.client_description,
              resistance: caple_14&.resistance,
              price: caple_14&.price || 0,
              unit: caple_14&.unit ? { id: caple_14.unit.id, name: caple_14.unit.name, abbreviation: caple_14.unit.abbreviation } : nil,
              ancho: caple_14&.ancho || folder_width,
              largo: caple_14&.largo || folder_length,
              quantity: folder_quantity,
              piecesPerMaterial: folder_pieces_per_sheet,
              totalSheets: folder_total_sheets,
              totalSquareMeters: folder_total_area,
              totalPrice: folder_total_area * (caple_14&.price || 0),
              subtotal_price: folder_total_area * (caple_14&.price || 0),
              comments: "Cartulina caple sulfatada 14 pts para folder institucional"
            }
            # Optionally add couche_150 as a secondary material if desired
          ],
          processes: [
            {
              process_id: offset_proc&.id,
              description: offset_proc&.name,
              unit: offset_proc&.unit&.abbreviation,
              unitPrice: offset_proc&.cost,
              materialId: caple_14&.id ? "#{caple_14.id}_1" : nil,
              materialDescription: caple_14&.description,
              price: ((offset_proc&.cost ? offset_proc.cost * folder_width * folder_length * folder_quantity / 10000.0 : 0).to_f), # m² pricing
              veces: 1,
              comments: "Impresión offset 4 tintas (CMYK) sobre toda el área"
            },
            {
              process_id: barniz_proc&.id,
              description: barniz_proc&.name,
              unit: barniz_proc&.unit&.abbreviation,
              unitPrice: barniz_proc&.cost,
              materialId: caple_14&.id ? "#{caple_14.id}_1" : nil,
              materialDescription: caple_14&.description,
              price: ((barniz_proc&.cost ? barniz_proc.cost * folder_width * folder_length * folder_quantity / 10000.0 : 0).to_f), # m² pricing
              veces: 1,
              comments: "Barniz UV spot en logotipo"
            },
            {
              process_id: laminado_proc&.id,
              description: laminado_proc&.name,
              unit: laminado_proc&.unit&.abbreviation,
              unitPrice: laminado_proc&.cost,
              materialId: caple_14&.id ? "#{caple_14.id}_1" : nil,
              materialDescription: caple_14&.description,
              price: ((laminado_proc&.cost ? laminado_proc.cost * folder_width * folder_length * folder_quantity / 10000.0 : 0).to_f), # m² pricing
              veces: 1,
              comments: "Laminado mate cobertura completa"
            },
            {
              process_id: hendido_proc&.id,
              description: hendido_proc&.name,
              unit: hendido_proc&.unit&.abbreviation,
              unitPrice: hendido_proc&.cost,
              materialId: caple_14&.id ? "#{caple_14.id}_1" : nil,
              materialDescription: caple_14&.description,
              price: (hendido_proc&.cost ? hendido_proc.cost * folder_quantity : 0).to_f, # pieza pricing
              veces: 1,
              comments: "Hendido y corte para bolsillos y doblez"
            }
          ],
          extras: [
            {
              extra_id: diseno_extra&.id,
              name: diseno_extra&.name,
              description: diseno_extra&.description,
              unit_price: (diseno_extra&.cost || 0).to_f,
              quantity: 1,
              total: (diseno_extra&.cost || 0).to_f * 1,
              comments: "Diseño gráfico del empaque"
            },
            {
              extra_id: placa_extra&.id,
              name: placa_extra&.name,
              description: placa_extra&.description,
              unit_price: (placa_extra&.cost || 0).to_f,
              quantity: 4,
              total: (placa_extra&.cost || 0).to_f * 4,
              comments: "Fabricación de placa offset (por tinta) para 4 tintas"
            },
            {
              extra_id: mockup_extra&.id,
              name: mockup_extra&.name,
              description: mockup_extra&.description,
              unit_price: (mockup_extra&.cost || 0).to_f,
              quantity: 1,
              total: (mockup_extra&.cost || 0).to_f * 1,
              comments: "Desarrollo de muestra física (mockup) para aprobación"
            },
            {
              extra_id: supervision_extra&.id,
              name: supervision_extra&.name,
              description: supervision_extra&.description,
              unit_price: (supervision_extra&.cost || 0).to_f,
              quantity: 1,
              total: (supervision_extra&.cost || 0).to_f * 1,
              comments: "Supervisión de producción"
            },
            {
              extra_id: envio_prueba_extra&.id,
              name: envio_prueba_extra&.name,
              description: envio_prueba_extra&.description,
              unit_price: (envio_prueba_extra&.cost || 0).to_f,
              quantity: 1,
              total: (envio_prueba_extra&.cost || 0).to_f * 1,
              comments: "Envío de prueba física al cliente"
            }
          ]
        }
      )
      folder_product.calculate_totals
      folder_product.save!
      folder_product.reload

      # Create the example product: Tríptico promocional 21×29.7 cm
      triptico_quantity = 3200
      triptico_width = 21.5
      triptico_length = 29.5
      couche_150 = materials.find_by(description: 'Papel couché brillante 150 g/m²')
      caple_12 = materials.find_by(description: 'Cartulina caple sulfatada 12 pts')
      offset_proc = manufacturing_processes.find_by(name: 'Impresión offset 4 tintas (CMYK)')
      barniz_proc = manufacturing_processes.find_by(name: 'Barniz UV spot')
      hendido_proc = manufacturing_processes.find_by(name: 'Hendido y corte')
      diseno_editorial_extra = extras.find_by(name: 'Diseño gráfico editorial')
      ajuste_archivos_extra = extras.find_by(name: 'Ajuste de archivos para impresión')
      placas_offset_extra = extras.find_by(name: 'Fabricación de placa offset (por tinta)')
      prueba_color_extra = extras.find_by(name: 'Prueba de color digital (matchprint)')
      supervision_editorial_extra = extras.find_by(name: 'Supervisión editorial')

      # For tríptico example:
      triptico_area_per_piece = triptico_width * triptico_length / 100.0 / 100.0 # m²
      triptico_pieces_per_sheet = 1 # For tríptico, assume 1 per sheet unless you have a better value
      triptico_total_sheets = (triptico_quantity.to_f / triptico_pieces_per_sheet).ceil
      triptico_total_area = triptico_total_sheets * triptico_area_per_piece

      triptico_product = products.create!(
        description: "Tríptico promocional 21×29.7 cm – Tríptico informativo doblado en 3 partes, impreso por ambos lados, con posible barniz brillante.",
        data: {
          general_info: {
            width: triptico_width,
            length: triptico_length,
            inner_measurements: nil,
            quantity: triptico_quantity,
            comments: "Tríptico informativo doblado en 3 partes, impreso por ambos lados, con posible barniz brillante."
          },
          materials: [
            {
              material_id: couche_150&.id,
              materialInstanceId: couche_150&.id ? "#{couche_150.id}_1" : nil,
              materialInstanceNumber: 1,
              displayName: couche_150&.description ? "#{couche_150.description} (1)" : nil,
              description: couche_150&.description,
              client_description: couche_150&.client_description,
              resistance: couche_150&.resistance,
              price: couche_150&.price || 0,
              unit: couche_150&.unit ? { id: couche_150.unit.id, name: couche_150.unit.name, abbreviation: couche_150.unit.abbreviation } : nil,
              ancho: couche_150&.ancho || triptico_width,
              largo: couche_150&.largo || triptico_length,
              quantity: triptico_quantity,
              piecesPerMaterial: triptico_pieces_per_sheet,
              totalSheets: triptico_total_sheets,
              totalSquareMeters: triptico_total_area,
              totalPrice: triptico_total_area * (couche_150&.price || 0),
              subtotal_price: triptico_total_area * (couche_150&.price || 0),
              comments: "Papel couché brillante 150 g/m² para tríptico"
            }
            # Optionally add caple_12 as a secondary material if desired
          ],
          processes: [
            {
              process_id: offset_proc&.id,
              description: offset_proc&.name,
              unit: offset_proc&.unit&.abbreviation,
              unitPrice: offset_proc&.cost,
              materialId: couche_150&.id ? "#{couche_150.id}_1" : nil,
              materialDescription: couche_150&.description,
              price: ((offset_proc&.cost ? offset_proc.cost * triptico_width * triptico_length * triptico_quantity / 10000.0 : 0).to_f), # m² pricing
              veces: 1,
              comments: "Impresión offset 4 tintas (CMYK) por ambos lados"
            },
            {
              process_id: barniz_proc&.id,
              description: barniz_proc&.name,
              unit: barniz_proc&.unit&.abbreviation,
              unitPrice: barniz_proc&.cost,
              materialId: couche_150&.id ? "#{couche_150.id}_1" : nil,
              materialDescription: couche_150&.description,
              price: ((barniz_proc&.cost ? barniz_proc.cost * triptico_width * triptico_length * triptico_quantity / 10000.0 : 0).to_f), # m² pricing
              veces: 1,
              comments: "Barniz UV spot en la portada o elementos gráficos"
            },
            {
              process_id: hendido_proc&.id,
              description: hendido_proc&.name,
              unit: hendido_proc&.unit&.abbreviation,
              unitPrice: hendido_proc&.cost,
              materialId: couche_150&.id ? "#{couche_150.id}_1" : nil,
              materialDescription: couche_150&.description,
              price: (hendido_proc&.cost ? hendido_proc.cost * triptico_quantity : 0).to_f, # pieza pricing
              veces: 1,
              comments: "Hendido y corte para los dobleces"
            }
          ],
          extras: [
            {
              extra_id: diseno_editorial_extra&.id,
              name: diseno_editorial_extra&.name,
              description: diseno_editorial_extra&.description,
              unit_price: (diseno_editorial_extra&.cost || 0).to_f,
              quantity: 1,
              total: (diseno_editorial_extra&.cost || 0).to_f * 1,
              comments: "Diseño gráfico editorial"
            },
            {
              extra_id: ajuste_archivos_extra&.id,
              name: ajuste_archivos_extra&.name,
              description: ajuste_archivos_extra&.description,
              unit_price: (ajuste_archivos_extra&.cost || 0).to_f,
              quantity: 1,
              total: (ajuste_archivos_extra&.cost || 0).to_f * 1,
              comments: "Ajuste de archivos para impresión"
            },
            {
              extra_id: placas_offset_extra&.id,
              name: placas_offset_extra&.name,
              description: placas_offset_extra&.description,
              unit_price: (placas_offset_extra&.cost || 0).to_f,
              quantity: 4,
              total: (placas_offset_extra&.cost || 0).to_f * 4,
              comments: "Fabricación de placas offset (por tinta) para 4 tintas"
            },
            {
              extra_id: prueba_color_extra&.id,
              name: prueba_color_extra&.name,
              description: prueba_color_extra&.description,
              unit_price: (prueba_color_extra&.cost || 0).to_f,
              quantity: 1,
              total: (prueba_color_extra&.cost || 0).to_f * 1,
              comments: "Prueba de color digital"
            },
            {
              extra_id: supervision_editorial_extra&.id,
              name: supervision_editorial_extra&.name,
              description: supervision_editorial_extra&.description,
              unit_price: (supervision_editorial_extra&.cost || 0).to_f,
              quantity: 1,
              total: (supervision_editorial_extra&.cost || 0).to_f * 1,
              comments: "Supervisión editorial"
            }
          ]
        }
      )
      triptico_product.calculate_totals
      triptico_product.save!
      triptico_product.reload

      # Create a second example quote using the folder and tríptico products
      Rails.logger.info "[setup_initial_data] Creating second demo quote..."
      second_quote = quotes.create!(
        project_name: "Campaña de Marketing Corporativo Q4 2024",
        customer_name: "Roberto Mendoza",
        organization: "TechCorp Solutions",
        email: "roberto.mendoza@techcorp.com",
        telephone: "+52 55 9876 5432",
        comments: "Cotización para materiales promocionales y corporativos del cuarto trimestre. Requerimos folder institucional para presentaciones ejecutivas y trípticos informativos para distribución masiva en eventos corporativos.",
        data: Quote.default_data
      )
      
      # Add the folder product to the quote
      second_quote.quote_products.create!(
        product: folder_product,
        quantity: 1
      )
      
      # Add the tríptico product to the quote
      second_quote.quote_products.create!(
        product: triptico_product,
        quantity: 1
      )
      
      # Calculate totals for the quote
      second_quote.calculate_totals
      
      # Add product details to the quote's data for frontend display
      second_quote.data['products'] = [
        {
          product_id: folder_product.id,
          description: folder_product.description,
          quantity: 2500,
          unit_price: folder_product.data['pricing']['final_price_per_piece'],
          total_price: folder_product.data['pricing']['final_price_per_piece'].to_f * 2500
        },
        {
          product_id: triptico_product.id,
          description: triptico_product.description,
          quantity: 3200,
          unit_price: triptico_product.data['pricing']['final_price_per_piece'],
          total_price: triptico_product.data['pricing']['final_price_per_piece'].to_f * 3200
        }
      ]
      second_quote.save!
      
      Rails.logger.info "[setup_initial_data] Second demo quote created: #{second_quote.quote_number}"
      
      # Create second example customer
      Rails.logger.info "[setup_initial_data] Creating second example customer..."
      customers.create!(
        name: "Roberto Mendoza",
        email: "roberto.mendoza@techcorp.com",
        phone: "+52 55 9876 5432",
        company: "TechCorp Solutions",
        address: "Av. Reforma 567, Col. Juárez, Ciudad de México, CDMX",
        notes: "Cliente corporativo especializado en tecnología. Requiere materiales promocionales de alta calidad para eventos y presentaciones ejecutivas. Prioriza acabados profesionales y materiales sustentables."
      )
      
      Rails.logger.info "[setup_initial_data] Second example customer created."
    rescue => e
      Rails.logger.error "[setup_initial_data] ERROR: #{e.class}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end

  def send_admin_notification
    AdminMailer.new_user_notification(self).deliver_later
  end

  def send_welcome_email
    UserMailer.welcome_email(self).deliver_later
  end

  def set_default_subscription_status
    self.subscription_status ||= 'trial'
  end
end
