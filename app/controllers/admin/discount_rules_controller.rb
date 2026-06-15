class Admin::DiscountRulesController < Admin::BaseController
  before_action :set_rule, only: [:edit, :update, :destroy]

  def index
    @rules = current_user.clinic.discount_rules.active.order(:min_slots)
  end

  def new
    @rule = DiscountRule.new
  end

  def create
    @rule = current_user.clinic.discount_rules.new(rule_params)

    if @rule.save
      redirect_to admin_discount_rules_path, notice: "Regra de desconto criada."
    else
      redirect_to admin_discount_rules_path, alert: @rule.errors.full_messages.to_sentence
    end
  end

  def edit; end

  def update
    if @rule.update(rule_params)
      redirect_to admin_discount_rules_path, notice: "Regra atualizada."
    else
      redirect_to admin_discount_rules_path, alert: @rule.errors.full_messages.to_sentence
    end
  end

  def destroy
    @rule.deactivate!
    redirect_to admin_discount_rules_path, notice: "Desconto excluído."
  end

  private

  def set_rule
    @rule = current_user.clinic.discount_rules.find(params[:id])
  end

  def rule_params
    params.require(:discount_rule).permit(:min_slots, :discount_percent, :active)
  end
end
