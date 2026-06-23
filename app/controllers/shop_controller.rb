class ShopController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    @extras = Current.clinic&.extras&.active&.ordered || []
  end
end
