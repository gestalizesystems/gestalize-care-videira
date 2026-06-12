require "rails_helper"

RSpec.describe "Admin::DiscountRules", type: :request do
  let(:clinic) { create(:clinic) }
  let(:owner)  { create(:user, :owner, clinic: clinic) }

  before { sign_in owner }

  describe "GET /admin/discount_rules" do
    it "renders index" do
      get admin_discount_rules_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /admin/discount_rules" do
    it "creates a rule" do
      expect {
        post admin_discount_rules_path, params: { discount_rule: { min_slots: 2, discount_percent: 10 } }
      }.to change(DiscountRule, :count).by(1)
    end
  end

  describe "DELETE /admin/discount_rules/:id" do
    let!(:rule) { create(:discount_rule, clinic: clinic) }

    it "deactivates the rule" do
      delete admin_discount_rule_path(rule)
      expect(rule.reload.active?).to be false
    end
  end
end
