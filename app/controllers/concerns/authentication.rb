module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :current_identity, :user_signed_in?
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def current_identity
    current_user || current_anonymous_identity
  end

  def user_signed_in?
    current_user.present?
  end

  def require_auth
    unless user_signed_in?
      redirect_to root_path, alert: "Необходимо войти в систему"
    end
  end

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: "Доступ запрещён"
    end
  end

  private

  def current_anonymous_identity
    return @current_anonymous_identity if defined?(@current_anonymous_identity)

    token = cookies.signed[:anon_token]
    if token
      token_hash = Digest::SHA256.hexdigest(token)
      @current_anonymous_identity = AnonymousIdentity.find_by(anon_token_hash: token_hash)
    end

    unless @current_anonymous_identity
      @current_anonymous_identity = create_anonymous_identity
    end

    @current_anonymous_identity
  end

  def create_anonymous_identity
    token = SecureRandom.urlsafe_base64(32)
    token_hash = Digest::SHA256.hexdigest(token)

    cookies.signed[:anon_token] = {
      value: token,
      expires: 1.year.from_now,
      httponly: true,
      same_site: :lax
    }

    AnonymousIdentity.create!(
      anon_token_hash: token_hash,
      last_ip: request.remote_ip,
      last_seen_at: Time.current
    )
  end
end
