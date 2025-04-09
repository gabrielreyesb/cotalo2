class Unit < ApplicationRecord
  has_many :materials
  has_many :manufacturing_processes
  has_many :extras

  validates :name, presence: true, uniqueness: true
  validates :abbreviation, presence: true, uniqueness: true

  before_destroy :check_for_dependencies

  private

  def check_for_dependencies
    if materials.any? || manufacturing_processes.any? || extras.any?
      errors.add(:base, 'No se puede eliminar una unidad que está siendo utilizada')
      throw :abort
    end
  end
end
