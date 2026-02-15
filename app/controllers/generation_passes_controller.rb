class GenerationPassesController < ApplicationController
  before_action :require_auth, only: [:new, :create, :confirmed]

  def limit_reached
    @has_active_pass = current_user && GenerationPass.active_for(current_user).exists?
  end

  def new
    if GenerationPass.active_for(current_user).exists?
      redirect_to new_creation_path, notice: "У вас уже есть активный безлимит"
      return
    end

    @price_cents = pass_price_cents
  end

  def create
    if GenerationPass.active_for(current_user).exists?
      redirect_to new_creation_path, notice: "У вас уже есть активный безлимит"
      return
    end

    price = pass_price_cents
    duration = pass_duration_hours

    pass = GenerationPass.create!(
      user: current_user,
      status: "active",
      starts_at: Time.current,
      ends_at: duration.hours.from_now,
      price_cents: price,
      currency: "RUB"
    )

    payment = Payment.create!(
      payable: pass,
      provider: "yookassa",
      status: "created",
      amount_cents: price,
      currency: "RUB",
      idempotence_key: SecureRandom.uuid
    )

    client = Payments::YookassaClient.new
    result = client.create_payment(
      amount_cents: price,
      currency: "RUB",
      description: "Безлимит генераций на #{duration} ч.",
      return_url: confirmed_generation_pass_url(pass),
      idempotence_key: payment.idempotence_key,
      metadata: { payment_id: payment.id, type: "generation_pass" }
    )

    payment.update!(
      provider_payment_id: result[:provider_payment_id],
      confirmation_url: result[:confirmation_url]
    )
    payment.pend!

    redirect_to result[:confirmation_url], allow_other_host: true
  rescue Payments::YookassaClient::PaymentError => e
    Rails.logger.error("[Payment] GenerationPass: #{e.message}")
    redirect_to new_generation_pass_path, alert: "Ошибка оплаты. Попробуйте ещё раз."
  end

  def confirmed
    @pass = current_user.generation_passes.find(params[:id])
  end

  private

  def pass_price_cents
    setting = AppSetting["pass_price_cents"]
    setting&.fetch("value", 10000) || 10000
  end

  def pass_duration_hours
    setting = AppSetting["pass_duration_hours"]
    setting&.fetch("value", 24) || 24
  end
end
