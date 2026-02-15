module Admin
  class AuditLogsController < BaseController
    def index
      @logs = AuditLog.includes(:actor_user).recent
      @logs = @logs.where(action: params[:action_filter]) if params[:action_filter].present?
      @logs = @logs.where(record_type: params[:record_type]) if params[:record_type].present?
      @logs = @logs.limit(100)
    end
  end
end
