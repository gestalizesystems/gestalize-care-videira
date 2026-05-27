require "rails_helper"

RSpec.describe "Scheduling::Carts", type: :request do
  let(:clinic)  { create(:clinic) }
  let(:av)      { create(:availability, clinic: clinic) }

  describe "GET /carrinho" do
    it "renders show" do
      get carrinho_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /carrinho/adicionar/:availability_id" do
    it "adds an availability to the cart" do
      post add_to_carrinho_path(availability_id: av.id)
      follow_redirect! if response.redirect?
      expect(session[:cart_ids]).to include(av.id)
    end

    it "alerts when availability is unavailable" do
      av.update!(status: "booked")
      post add_to_carrinho_path(availability_id: av.id)
      expect(flash[:alert]).to include("indisponível")
    end
  end

  describe "DELETE /carrinho/remover/:availability_id" do
    before { post add_to_carrinho_path(availability_id: av.id) }

    it "removes the availability" do
      delete remove_from_carrinho_path(availability_id: av.id)
      expect(session[:cart_ids]).not_to include(av.id)
    end
  end

  describe "DELETE /carrinho" do
    before { post add_to_carrinho_path(availability_id: av.id) }

    it "clears the cart" do
      delete carrinho_path
      expect(session[:cart_ids]).to be_blank
    end
  end
end
