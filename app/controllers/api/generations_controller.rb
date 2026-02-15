module Api
  class GenerationsController < BaseController
    def status
      generation = Generation.find_by_hashid(params[:id])
      return render json: { error: "not found" }, status: :not_found unless generation

      terminal_statuses = %w[succeeded partial failed canceled]

      progress_step = case generation.status
      when "created", "queued" then 1
      when "running" then 2
      when "succeeded", "partial" then 3
      else 3
      end

      render json: {
        status: generation.status,
        progress_step: progress_step,
        is_terminal: terminal_statuses.include?(generation.status)
      }
    end
  end
end
