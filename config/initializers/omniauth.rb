Rails.application.config.middleware.use OmniAuth::Builder do
  provider :vkontakte,
    Rails.application.credentials.dig(:omniauth, :vkontakte, :client_id),
    Rails.application.credentials.dig(:omniauth, :vkontakte, :client_secret)

  provider :yandex,
    Rails.application.credentials.dig(:omniauth, :yandex, :client_id),
    Rails.application.credentials.dig(:omniauth, :yandex, :client_secret)

  provider :google_oauth2,
    Rails.application.credentials.dig(:omniauth, :google, :client_id),
    Rails.application.credentials.dig(:omniauth, :google, :client_secret),
    name: :google
end

OmniAuth.config.allowed_request_methods = [ :post ]
