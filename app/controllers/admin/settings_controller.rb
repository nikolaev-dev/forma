module Admin
  class SettingsController < BaseController
    def index
      @settings = AppSetting.order(:key)
    end

    def update
      setting = AppSetting.find_by!(key: params[:key])
      before_val = setting.value
      new_value = params[:setting][:value]

      # Parse JSON if it looks like JSON
      parsed = begin
        JSON.parse(new_value)
      rescue JSON::ParserError
        { "value" => new_value }
      end

      setting.update!(value: parsed, updated_by_user: current_user)
      audit!(action: "settings.update", record: setting, before: { value: before_val }, after: { value: parsed })
      redirect_to admin_settings_path, notice: "Настройка \"#{setting.key}\" обновлена"
    end
  end
end
