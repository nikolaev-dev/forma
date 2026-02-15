require "application_system_test_case"

class CreationFlowTest < ApplicationSystemTestCase
  setup do
    @style = create(:style, name: "Минимализм", slug: "minimalism", popularity_score: 5.0)
    @category = create(:tag_category, name: "Настроение", slug: "mood", is_active: true)
    @tag = create(:tag, name: "Спокойствие", slug: "calm", tag_category: @category)
  end

  test "catalog displays styles and links to creation" do
    visit root_path
    assert_text "FORMA"
    assert_text "Минимализм"
  end

  test "creation form displays prompt field and tags" do
    visit new_creation_path(style: "minimalism")
    assert_text "Минимализм"
    assert_text "Создать дизайн"
    assert_text "Спокойствие"
    assert_selector "textarea#user_prompt"
  end

  test "creation form submits with prompt via controller" do
    # Button is disabled without JS validation, so test the POST directly
    GenerationJob.stubs(:perform_later)

    page.driver.post creations_path, creation: {
      user_prompt: "Красивый блокнот с горами",
      style_slug: "minimalism"
    }

    assert_equal 302, page.driver.response.status
    follow_redirect!
    assert_text "Создаём ваш дизайн"
  end

  private

  def follow_redirect!
    visit page.driver.response.location
  end

  test "result page shows variants" do
    generation = create(:generation, status: "succeeded")
    create(:generation_variant, :main, :succeeded, generation: generation)
    create(:generation_variant, :mutation_a, :succeeded, generation: generation)
    create(:generation_variant, :mutation_b, :succeeded, generation: generation)

    visit result_creation_path(generation.design)
    assert_text "Основной вариант"
    assert_text "Мутация A"
    assert_text "Мутация B"
    assert_text "Выбрать этот дизайн"
  end

  test "progress page shows progress indicator" do
    generation = create(:generation, status: "running")

    visit progress_creation_path(generation.design)
    assert_text "Создаём ваш дизайн"
    assert_text "Подготовка"
    assert_text "Генерация"
    assert_text "Готово"
  end

  test "progress redirects to result for completed generation" do
    generation = create(:generation, status: "succeeded")
    create(:generation_variant, :main, :succeeded, generation: generation)

    visit progress_creation_path(generation.design)
    assert_current_path result_creation_path(generation.design)
    assert_text "Основной вариант"
  end
end
