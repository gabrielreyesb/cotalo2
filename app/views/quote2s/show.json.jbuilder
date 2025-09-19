json.id @quote.id
json.quote_number @quote.quote_number
json.client_name @quote.client_name
json.client_company @quote.client_company
json.client_email @quote.client_email
json.client_phone @quote.client_phone
json.description @quote.description
json.created_at @quote.created_at
json.updated_at @quote.updated_at

json.product_data @quote.product_data

json.pricing @quote.pricing do |key, value|
  json.set! key, value
end

json.materials @quote.materials do |material|
  json.id material['id']
  json.description material['description']
  json.client_description material['client_description']
  json.cost material['cost']
  json.resistance material['resistance']
  json.ancho material['ancho']
  json.largo material['largo']
  json.weight material['weight']
  
  if material['unit']
    json.unit do
      json.id material['unit']['id']
      json.name material['unit']['name']
      json.abbreviation material['unit']['abbreviation']
    end
  end
  
  json.processes material['processes'] do |process|
    json.id process['id']
    json.price process['price']
    json.side process['side']
    json.times process['times']
  end
end

json.processes @quote.processes do |process|
  json.id process['id']
  json.price process['price']
  json.side process['side']
  json.times process['times']
end

json.extras @quote.extras do |extra|
  json.id extra['id']
  json.name extra['name']
  json.description extra['description']
  json.cost extra['cost']
  json.quantity extra['quantity']
end

json.user do
  json.id @quote.user.id
  json.email @quote.user.email
end
