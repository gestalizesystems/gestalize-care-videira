require "rails_helper"

RSpec.describe "Scheduling::Bookings", type: :request do
  let(:clinic)  { create(:clinic) }
  let(:dentist) { create(:user, :dentist, clinic: clinic) }
  let(:av)      { create(:availability, clinic: clinic) }

  let(:pix_result) do
    ApplicationService::Result.new(
      success: true,
      value: {
        gateway_id:  "SANDBOX_1",
        pix_qr_code: "00020...",
        pix_qr_url:  "",
        expires_at:  30.minutes.from_now
      },
      error: nil
    )
  end

  before do
    sign_in dentist
    allow(MercadoPago::PixCreator).to receive(:call).and_return(pix_result)
  end

  describe "GET /reservas/confirmar" do
    it "redirects to root when cart is empty" do
      get confirmar_reservas_path
      expect(response).to redirect_to(root_path)
    end

    it "renders the confirmation page with items" do
      post add_to_carrinho_path(availability_id: av.id)
      get confirmar_reservas_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /reservas/confirmar" do
    it "creates a booking group and redirects to payment" do
      post add_to_carrinho_path(availability_id: av.id)
      expect {
        post confirmar_reservas_path
      }.to change(BookingGroup, :count).by(1)
      expect(response).to redirect_to(pagamento_path(BookingGroup.last.payment))
    end

    it "clears the cart on success" do
      post add_to_carrinho_path(availability_id: av.id)
      post confirmar_reservas_path
      expect(session[:cart_ids]).to be_blank
    end
  end

  describe "GET /reservas" do
    it "lists user reservations" do
      create(:booking_group, :with_bookings, clinic: clinic, dentist: dentist)
      get reservas_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /reservas/:id/cancelar" do
    let(:future_av) { create(:availability, clinic: clinic, date: 10.days.from_now.to_date, starts_at: "10:00", ends_at: "11:00") }
    let(:group)     { create(:booking_group, clinic: clinic, dentist: dentist, status: "confirmed") }
    let!(:booking)  { create(:booking, clinic: clinic, booking_group: group, availability: future_av, dentist: dentist, status: "confirmed") }

    it "cancels a confirmed booking" do
      patch cancelar_reserva_path(booking)
      expect(booking.reload.cancelled?).to be true
    end
  end
end
