module Authorized
  extend ActiveSupport::Concern

  def authorize
    if session[:user_id] != nil
      @user = User.find(session[:user_id])
      return
    end

    # if you can't find the session, look for a jwt
    header = request.headers['Authorization']
    token = header.split(' ').last if header
    decoded = JwtService.decode(token)
    if decoded
      @user = User.find(decoded[:user_id])
      return
    end

    render json: {
      "error": "No session found"
    }, status: :unauthorized
    return
  end
end
