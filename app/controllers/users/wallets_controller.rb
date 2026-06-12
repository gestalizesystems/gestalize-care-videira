class Users::WalletsController < ApplicationController
  before_action :authenticate_user!

  def show
    @credit_cents = Credit.balance_for(user: current_user, clinic: current_user.clinic)
  end
end
