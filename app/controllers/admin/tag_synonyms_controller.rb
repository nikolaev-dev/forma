module Admin
  class TagSynonymsController < BaseController
    def create
      @tag = Tag.find(params[:tag_id])
      synonym = @tag.tag_synonyms.build(synonym_params)

      if synonym.save
        audit!(action: "tag_synonym.create", record: @tag, after: { phrase: synonym.phrase })
        redirect_to edit_admin_tag_path(@tag), notice: "Синоним добавлен"
      else
        redirect_to edit_admin_tag_path(@tag), alert: synonym.errors.full_messages.join(", ")
      end
    end

    def destroy
      @tag = Tag.find(params[:tag_id])
      synonym = @tag.tag_synonyms.find(params[:id])
      audit!(action: "tag_synonym.delete", record: @tag, before: { phrase: synonym.phrase })
      synonym.destroy!
      redirect_to edit_admin_tag_path(@tag), notice: "Синоним удалён"
    end

    private

    def synonym_params
      params.require(:tag_synonym).permit(:phrase)
    end
  end
end
