class BackfillUserClinics < ActiveRecord::Migration[7.2]
  # Usuários criados via Google ficaram sem clinic_id e sumiam da listagem admin.
  # Atribui a clínica existente para que voltem a ser gerenciáveis.
  def up
    clinic = Clinic.order(:created_at).first
    return unless clinic

    User.where(clinic_id: nil).update_all(clinic_id: clinic.id)
  end

  def down
    # irreversível — não há como saber quais eram nulos
  end
end
