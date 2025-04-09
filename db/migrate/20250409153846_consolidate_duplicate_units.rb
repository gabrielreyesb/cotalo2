class ConsolidateDuplicateUnits < ActiveRecord::Migration[7.1]
  def up
    # Find all units with name 'mt2'
    mt2_units = Unit.where(name: 'mt2').order(:created_at)
    
    if mt2_units.size > 1
      # Keep the first one (oldest) and use it as the reference
      reference_unit = mt2_units.first
      
      # Get all other duplicate units
      duplicate_units = mt2_units.offset(1)
      
      duplicate_units.each do |duplicate_unit|
        # Update all materials to use the reference unit
        Material.where(unit_id: duplicate_unit.id).update_all(unit_id: reference_unit.id)
        
        # Update all manufacturing processes
        ManufacturingProcess.where(unit_id: duplicate_unit.id).update_all(unit_id: reference_unit.id)
        
        # Update all extras
        Extra.where(unit_id: duplicate_unit.id).update_all(unit_id: reference_unit.id)
        
        # Delete the duplicate unit
        duplicate_unit.delete
      end
    end
    
    # Update the remaining mt2 unit to have proper name and abbreviation
    Unit.where(name: 'mt2').update_all(name: 'Metro cuadrado', abbreviation: 'm²')
  end

  def down
    # This migration cannot be reversed
    raise ActiveRecord::IrreversibleMigration
  end
end 