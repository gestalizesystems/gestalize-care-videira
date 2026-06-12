require "rails_helper"

RSpec.describe DiscountCalculator, type: :service do
  let(:clinic)  { create(:clinic) }
  let(:service) { create(:service, clinic: clinic, price_cents: 15_000) }

  def make_availability
    create(:availability, clinic: clinic, service: service)
  end

  context "with no availabilities" do
    it "returns a zero total with no discount" do
      result = DiscountCalculator.call(availability_ids: [], clinic: clinic)
      expect(result.success?).to be true
      expect(result.value[:subtotal_cents]).to eq(0)
      expect(result.value[:discount_cents]).to eq(0)
      expect(result.value[:total_cents]).to eq(0)
    end
  end

  context "with 1 slot and no applicable discount rule" do
    it "returns full price with no discount" do
      av = make_availability
      result = DiscountCalculator.call(availability_ids: [av.id], clinic: clinic)

      expect(result.success?).to be true
      expect(result.value[:subtotal_cents]).to eq(15_000)
      expect(result.value[:discount_cents]).to eq(0)
      expect(result.value[:total_cents]).to eq(15_000)
      expect(result.value[:discount_rule]).to be_nil
    end
  end

  context "with 2 slots and a matching discount rule (10%)" do
    before { create(:discount_rule, clinic: clinic, min_slots: 2, discount_percent: 10) }

    it "applies discount correctly" do
      av1 = make_availability
      av2 = make_availability
      result = DiscountCalculator.call(availability_ids: [av1.id, av2.id], clinic: clinic)

      expect(result.success?).to be true
      expect(result.value[:subtotal_cents]).to eq(30_000)
      expect(result.value[:discount_cents]).to eq(3_000)
      expect(result.value[:total_cents]).to eq(27_000)
    end
  end

  context "with 3 slots and tiered rules" do
    before do
      create(:discount_rule, clinic: clinic, min_slots: 2, discount_percent: 5)
      create(:discount_rule, clinic: clinic, min_slots: 3, discount_percent: 15)
    end

    it "uses the highest qualifying rule" do
      avs = 3.times.map { make_availability }
      result = DiscountCalculator.call(availability_ids: avs.map(&:id), clinic: clinic)

      expect(result.value[:discount_percent]).to eq(15)
      expect(result.value[:discount_cents]).to eq(6_750) # 45_000 * 0.15 = 6750
    end
  end

  it "ignores availability_ids from other clinics" do
    other_clinic = create(:clinic)
    other_av = create(:availability, clinic: other_clinic)
    own_av   = make_availability

    result = DiscountCalculator.call(availability_ids: [own_av.id, other_av.id], clinic: clinic)
    expect(result.value[:availabilities].size).to eq(1)
  end
end
