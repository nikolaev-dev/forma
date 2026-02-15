module Admin
  class BaseController < ApplicationController
    before_action :require_admin
    layout "admin"

    private

    def audit!(action:, record: nil, before: {}, after: {})
      AuditLog.log!(
        actor: current_user,
        action: action,
        record: record,
        before: before,
        after: after,
        ip: request.remote_ip
      )
    end
  end
end
