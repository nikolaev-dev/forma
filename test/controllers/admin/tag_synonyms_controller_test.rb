require "test_helper"

class Admin::TagSynonymsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin)
    sign_in_as(@admin)
    @tag = create(:tag)
  end

  test "create adds synonym to tag" do
    assert_difference "TagSynonym.count", 1 do
      post admin_tag_synonyms_path(@tag), params: {
        tag_synonym: { phrase: "новый синоним" }
      }
    end
    assert_redirected_to edit_admin_tag_path(@tag)
    assert_equal "новый синоним", @tag.tag_synonyms.last.phrase
  end

  test "create logs audit" do
    assert_difference "AuditLog.count", 1 do
      post admin_tag_synonyms_path(@tag), params: {
        tag_synonym: { phrase: "аудит синоним" }
      }
    end
    assert_equal "tag_synonym.create", AuditLog.last.action
  end

  test "create with invalid data shows error" do
    create(:tag_synonym, tag: @tag, phrase: "дубль")
    post admin_tag_synonyms_path(@tag), params: {
      tag_synonym: { phrase: "дубль" }
    }
    assert_redirected_to edit_admin_tag_path(@tag)
    assert flash[:alert].present?
  end

  test "destroy removes synonym" do
    synonym = create(:tag_synonym, tag: @tag, phrase: "удалить")

    assert_difference "TagSynonym.count", -1 do
      delete admin_tag_synonym_path(@tag, synonym)
    end
    assert_redirected_to edit_admin_tag_path(@tag)
  end

  test "destroy logs audit" do
    synonym = create(:tag_synonym, tag: @tag, phrase: "аудит удаление")

    assert_difference "AuditLog.count", 1 do
      delete admin_tag_synonym_path(@tag, synonym)
    end
    assert_equal "tag_synonym.delete", AuditLog.last.action
  end
end
