class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :create

  def create
    auth = request.env["omniauth.auth"]
    identity = OauthIdentity.find_by(provider: map_provider(auth.provider), uid: auth.uid)

    if identity
      user = identity.user
      identity.update!(
        access_token: auth.credentials.token,
        refresh_token: auth.credentials.refresh_token,
        expires_at: auth.credentials.expires_at ? Time.at(auth.credentials.expires_at) : nil,
        raw_profile: auth.info.to_h
      )
    else
      user = find_or_create_user(auth)
      user.oauth_identities.create!(
        provider: map_provider(auth.provider),
        uid: auth.uid,
        access_token: auth.credentials.token,
        refresh_token: auth.credentials.refresh_token,
        expires_at: auth.credentials.expires_at ? Time.at(auth.credentials.expires_at) : nil,
        raw_profile: auth.info.to_h
      )
    end

    session[:user_id] = user.id
    user.update!(last_seen_at: Time.current)

    redirect_to root_path
  end

  def destroy
    session.delete(:user_id)
    redirect_to root_path
  end

  def failure
    redirect_to root_path, alert: "Ошибка авторизации: #{params[:message]}"
  end

  private

  def find_or_create_user(auth)
    email = auth.info.email
    user = User.find_by(email: email) if email.present?
    user || User.create!(
      email: email,
      name: auth.info.name
    )
  end

  def map_provider(provider)
    case provider.to_s
    when "vkontakte" then "vk"
    when "google_oauth2", "google" then "google"
    else provider.to_s
    end
  end
end
