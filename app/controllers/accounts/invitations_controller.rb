module Accounts
  class InvitationsController < Accounts::BaseController
    skip_before_action :authorize_user!, only: %i[accept accepted]
    before_action :authorize_owner!, except: %i[accept accepted]

    def new
      @invitation = Invitation.new
    end

    def create
      @invitation = Invitation.new(invitation_params)
      @invitation.save
      InvitationMailer.invite(@invitation, current_account).deliver_later
      flash[:notice] = "#{@invitation.email} has been invited."
      redirect_to root_url
    end

    def accept
      store_location_for(:user, request.fullpath)
      @invitation = Invitation.find_by(token: params[:id])
    end

    def accepted
      @invitation = Invitation.find_by(token: params[:id])
      if user_signed_in?
        user = current_user
      else
        user = User.create!(user_params)
        sign_in(user)
      end

      current_account.users << user

      flash[:notice] = "You have joined the #{current_account.name} account."
      redirect_to root_url(subdomain: current_account.subdomain)
    end

    private

    def user_params
      params[:user].permit(:email, :password, :password_confirmation)
    end

    def authorize_owner!
      unless owner?
        flash[:error] = 'Only owner can access books'
        redirect_to root_url(subdomain: current_user.subdomain)
      end
    end

    def invitation_params
      params.require(:invitation).permit(:email)
    end
  end
end
