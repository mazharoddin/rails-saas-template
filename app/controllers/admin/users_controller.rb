# Encoding: utf-8

# Copyright (c) 2014, Richard Buggy
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Provides plans administration in the admin section
class Admin::UsersController < Admin::ApplicationController
  before_action :find_user, only: [:destroy, :edit, :show, :update, :accounts, :user_invitations]

  authorize_resource

  def index
    @users = User.page(params[:page])
  end

  def create
    @user = User.new(users_params)
    if @user.save
      UserMailer.welcome(@user).deliver_now
      AppEvent.success("Created user #{@user}", nil, current_user)
      logger.info { "User '#{@user}' created - #{admin_user_url(@user)}" }
      redirect_to admin_user_path(@user), notice: 'User was successfully created.'
    else
      logger.debug { "User create failed #{@user.inspect}" }
      render 'new'
    end
  end

  def edit
  end

  def new
    @user = User.new
  end

  def show
  end

  def update
    p = users_params
    if p[:password].blank? && p[:password_confirmation].blank?
      p.delete(:password)
      p.delete(:password_confirmation)
      logger.debug { 'Password is blank. Not updating the password.' }
    end
    if @user.update_attributes(p)
      AppEvent.success("Updated user #{@user}", nil, current_user)
      logger.info { "User '#{@user}' updated - #{admin_user_url(@user)}" }
      redirect_to admin_user_path(@user), notice: 'User was successfully updated.'
    else
      logger.debug { "User update failed #{@user.inspect}" }
      render 'edit'
    end
  end

  def destroy
    if @user.destroy
      AppEvent.info("Deleted user #{@user}", nil, current_user)
      logger.info { "User '#{@user}' destroyed - #{admin_user_url(@user)}" }
      redirect_to admin_users_path, notice: 'User was successfully removed.'
    else
      logger.debug { "User destroy failed #{@user.inspect}" }
      redirect_to admin_user_path(@user), alert: 'User could not be removed.'
    end
  end

  def accounts
    @user_permissions = @user.user_permissions.includes(:account).page(params[:page])
  end

  def user_invitations
    @user_invitations = UserInvitation.where(email: @user.email).page(params[:page])
  end

  private

  def find_user
    if params[:user_id]
      @user = User.find(params[:user_id])
    else
      @user = User.find(params[:id])
    end
  end

  def users_params
    params.require(:user).permit(:active,
                                 :email,
                                 :first_name,
                                 :last_name,
                                 :password,
                                 :password_confirmation,
                                 :super_admin)
  end

  def set_nav_item
    @nav_item = 'users'
  end
end
