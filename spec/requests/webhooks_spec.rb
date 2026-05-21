require "rails_helper"

RSpec.describe "Webhooks", type: :request do
  let(:clinic)  { create(:clinic) }
  let(:patient) { create(:user, :dentist, clinic: clinic) }
  let(:group)   { create(:booking_group, clinic: clinic, dentist: patient) }
  let!(:payment) { create(:payment, clinic: clinic, booking_group: group) }

  before do
    ENV["MERCADOPAGO_WEBHOOK_SECRET"] = "mock-webhook-secret-replace-me"

    allow(MercadoPago::PaymentFinder).to receive(:call).and_return(
      ApplicationService::Result.new(
        success: true,
        value: { "external_reference" => group.id, "status" => "approved" },
        error: nil
      )
    )
    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
  end

  after { ENV.delete("MERCADOPAGO_WEBHOOK_SECRET") }

  # action: "payment.updated" is required for the controller to call PaymentConfirmer
  let(:payload) do
    { type: "payment", action: "payment.updated", data: { id: payment.gateway_id } }.to_json
  end

  let(:headers) do
    { "CONTENT_TYPE" => "application/json", "x-signature" => "ts=1,v1=mock", "x-request-id" => "req-1" }
  end

  describe "POST /webhooks/mercadopago" do
    it "returns 200 OK" do
      post mercadopago_webhook_path, params: payload, headers: headers
      expect(response).to have_http_status(:ok)
    end

    it "confirms the booking group" do
      post mercadopago_webhook_path, params: payload, headers: headers
      expect(group.reload.status).to eq("confirmed")
    end

    context "with invalid signature and real secret" do
      before { ENV["MERCADOPAGO_WEBHOOK_SECRET"] = "real-secret-key" }

      it "returns 401" do
        post mercadopago_webhook_path, params: payload, headers: headers
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
