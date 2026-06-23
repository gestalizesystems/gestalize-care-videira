class Users::ProfileCompletionsController < ApplicationController
  skip_before_action :require_complete_profile

  def show
    return redirect_to after_sign_in_path_for(current_user) if current_user.profile_complete?

    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(completion_params)
      redirect_to after_sign_in_path_for(@user), notice: "Cadastro concluído. Bem-vindo(a)!"
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def completion_params
    params.require(:user).permit(:cpf, :cro, :phone, :specialty, :terms_accepted)
  end
end
