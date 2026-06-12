require "rails_helper"

RSpec.describe DiscountRule, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:clinic) }
    it { is_expected.to have_many(:booking_groups) }
  end

  describe "validations" do
    subject { build(:discount_rule) }

    it { is_expected.to validate_presence_of(:min_slots) }
    it { is_expected.to validate_presence_of(:discount_percent) }
    it { is_expected.to validate_numericality_of(:min_slots).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:discount_percent).is_in(1..100) }

    it "enforces uniqueness of min_slots per clinic among active rules" do
      rule = create(:discount_rule, min_slots: 2)
      duplicate = build(:discount_rule, min_slots: 2, clinic: rule.clinic)
      expect(duplicate).not_to be_valid
    end

    it "allows same min_slots across different clinics" do
      create(:discount_rule, min_slots: 2)
      other_clinic = create(:clinic)
      rule2 = build(:discount_rule, min_slots: 2, clinic: other_clinic)
      expect(rule2).to be_valid
    end

    it "allows same min_slots when existing rule is inactive" do
      inactive = create(:discount_rule, :inactive, min_slots: 2)
      new_rule = build(:discount_rule, min_slots: 2, clinic: inactive.clinic)
      expect(new_rule).to be_valid
    end
  end

  describe ".best_for" do
    let(:clinic) { create(:clinic) }

    let!(:two_slot_rule)   { create(:discount_rule, clinic: clinic, min_slots: 2, discount_percent: 5) }
    let!(:three_slot_rule) { create(:discount_rule, :large, clinic: clinic) } # min_slots:3, discount_percent:15

    it "returns nil when slot count is below minimum" do
      expect(DiscountRule.best_for(clinic.id, 1)).to be_nil
    end

    it "returns the best matching rule for 2 slots" do
      rule = DiscountRule.best_for(clinic.id, 2)
      expect(rule.discount_percent).to eq(5)
    end

    it "returns the highest matching rule for 3+ slots" do
      rule = DiscountRule.best_for(clinic.id, 3)
      expect(rule.discount_percent).to eq(15)
    end
  end

  describe "#deactivate!" do
    it "sets active to false" do
      rule = create(:discount_rule)
      expect { rule.deactivate! }.to change { rule.reload.active }.from(true).to(false)
    end
  end
end
