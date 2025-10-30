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

    # can't use function becuase we need :created status
    render json: {
      "user": {
        "id": @user.id,
        "username": @user.username,
        "created_at": @user.created_at,
        "last_active_at": @user.last_active_at
      },
      "token": @jwt_token
    }, status: :created
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
    render_user_info_with_token()
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
    render_user_info_with_token()
  end

  def me
    render_user_info()
  end

  private

  def render_user_info
    render json: {
      "id": @user.id,
      "username": @user.username,
      "created_at": @user.created_at,
      "last_active_at": @user.last_active_at
    }, status: :ok
  end

  def render_user_info_with_token
    render json: {
      "user": {
        "id": @user.id,
        "username": @user.username,
        "created_at": @user.created_at,
        "last_active_at": @user.last_active_at
      },
      "token": @jwt_token
    }, status: :ok
  end
end
