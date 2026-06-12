class Scheduling::CartsController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    @cart_availabilities = cart_availabilities
  end

  def add
    av = Availability.available.find_by(id: params[:availability_id])

    if av.nil?
      return redirect_back(fallback_location: root_path, alert: "Horário indisponível.")
    end

    cart_ids << av.id unless cart_ids.include?(av.id)
    session[:cart_ids] = cart_ids

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back(fallback_location: root_path) }
    end
  end

  def remove
    cart_ids.delete(params[:availability_id])
    session[:cart_ids] = cart_ids

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back(fallback_location: carrinho_path) }
    end
  end

  def destroy
    session.delete(:cart_ids)
    redirect_back(fallback_location: root_path)
  end

  private

  def cart_ids
    @cart_ids ||= Array(session[:cart_ids])
  end

  def cart_availabilities
    return [] if cart_ids.empty?
    Availability.where(id: cart_ids).includes(:service, :dentist).order(:date, :starts_at)
  end
end
