json.array! @quote2s do |quote|
  json.id quote.id
  json.quote_number quote.quote_number
  json.client_name quote.client_name
  json.client_company quote.client_company
  json.client_email quote.client_email
  json.description quote.description
  json.created_at quote.created_at
  json.updated_at quote.updated_at
  
  json.pricing do
    json.total_price quote.pricing['total_price']
    json.final_price_per_piece quote.pricing['final_price_per_piece']
  end
  
  json.general_info do
    json.quantity quote.general_info['quantity']
    json.width quote.general_info['width']
    json.length quote.general_info['length']
  end
  
  json.materials_count quote.materials.count
  json.processes_count quote.processes.count
  json.extras_count quote.extras.count
end
