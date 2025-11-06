class AuthController < ApplicationController
  include Authorized
  before_action :authorize, only: [:me]

  def register
    if params[:password].length == 0
      render json: {"errors": ["Password is too short"]}, status: :unprocessable_entity
      return
    elsif User.find_by(username: params[:username]) != nil
      render json: {"errors": ["Username has already been taken"]}, status: :unprocessable_entity
      return
    end

    @user = User.create!(username: params[:username], password: params[:password])
    ExpertProfile.create!(user: @user)

    @jwt_token = JwtService.encode(@user)
    session[:user_id] = @user.id

    render json: FormatterService.format_user_token(@user, @jwt_token), status: :created
  end

  def login
    @user = User.find_by(username: params[:username])
    authenticated = @user&.authenticate(params[:password])
    if !authenticated
      render json: { error: "Invalid username or password" }, status: :unauthorized
      return
    end

    @jwt_token = JwtService.encode(@user)
    session[:user_id] = @user.id
    render json: FormatterService.format_user_token(@user, @jwt_token), status: :ok
  end

  def logout
    reset_session()

    render json: {
      "message": "Logged out successfully"
    }, status: :ok
  end

  def refresh
    if session[:user_id] != nil
      @user = User.find(session[:user_id])
    else
      render json: {
        "error": "No session found"
      }, status: :unauthorized
      return
    end

    @jwt_token = JwtService.encode(@user)
    render json: FormatterService.format_user_token(@user, @jwt_token), status: :ok
  end

  def me
    render json: FormatterService.format_user(@user), status: :ok
  end
end
