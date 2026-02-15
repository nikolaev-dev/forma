require "test_helper"

class CreationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @style = create(:style, name: "Минимализм", slug: "minimalism")
    @category = create(:tag_category, name: "Настроение", slug: "mood", is_active: true)
    @tag1 = create(:tag, name: "Спокойствие", slug: "calm", tag_category: @category)
    @tag2 = create(:tag, name: "Энергия", slug: "energy", tag_category: @category)
  end

  # --- new ---

  test "new renders creation form" do
    get new_creation_path
    assert_response :success
    assert_select "textarea"
    assert_select "button[type=submit]"
  end

  test "new with style param preselects style" do
    get new_creation_path(style: "minimalism")
    assert_response :success
    assert_match "Минимализм", response.body
  end

  test "new shows available tags grouped by category" do
    get new_creation_path
    assert_response :success
    assert_match "Настроение", response.body
    assert_match "Спокойствие", response.body
    assert_match "Энергия", response.body
  end

  test "new hides banned tags" do
    create(:tag, :banned, name: "Запрещённый", tag_category: @category)
    get new_creation_path
    assert_no_match "Запрещённый", response.body
  end

  # --- create ---

  test "create launches generation and redirects to progress" do
    GenerationJob.stubs(:perform_later)

    post creations_path, params: {
      creation: {
        user_prompt: "Красивый минималистичный блокнот",
        style_slug: @style.slug,
        tag_ids: [ @tag1.id, @tag2.id ]
      }
    }

    assert_response :redirect
    generation = Generation.last
    assert generation.present?
    assert_redirected_to progress_creation_path(generation.design)
  end

  test "create without prompt shows error" do
    post creations_path, params: {
      creation: {
        user_prompt: "",
        style_slug: @style.slug
      }
    }

    assert_response :unprocessable_entity
    assert_match "Опишите", response.body
  end

  test "create works without style" do
    GenerationJob.stubs(:perform_later)

    post creations_path, params: {
      creation: {
        user_prompt: "Блокнот с горами"
      }
    }

    assert_response :redirect
  end

  test "create works without tags" do
    GenerationJob.stubs(:perform_later)

    post creations_path, params: {
      creation: {
        user_prompt: "Просто блокнот",
        style_slug: @style.slug,
        tag_ids: []
      }
    }

    assert_response :redirect
  end

  # --- progress ---

  test "progress renders for running generation" do
    generation = create(:generation, status: "running")

    get progress_creation_path(generation.design)
    assert_response :success
    assert_match "generation-progress", response.body
  end

  test "progress redirects to result when generation succeeded" do
    generation = create(:generation, status: "succeeded")

    get progress_creation_path(generation.design)
    assert_redirected_to result_creation_path(generation.design)
  end

  test "progress redirects to result when generation partial" do
    generation = create(:generation, status: "partial")

    get progress_creation_path(generation.design)
    assert_redirected_to result_creation_path(generation.design)
  end

  # --- result ---

  test "result renders succeeded variants" do
    generation = create(:generation, status: "succeeded")
    create(:generation_variant, :main, :succeeded, generation: generation)
    create(:generation_variant, :mutation_a, :succeeded, generation: generation)
    create(:generation_variant, :mutation_b, :succeeded, generation: generation)

    get result_creation_path(generation.design)
    assert_response :success
    assert_match "Основной вариант", response.body
    assert_match "Мутация A", response.body
    assert_match "Мутация B", response.body
  end

  test "result only shows succeeded variants" do
    generation = create(:generation, status: "partial")
    create(:generation_variant, :main, :succeeded, generation: generation)
    create(:generation_variant, :mutation_a, :failed, generation: generation)
    create(:generation_variant, :mutation_b, :succeeded, generation: generation)

    get result_creation_path(generation.design)
    assert_response :success
    assert_match "Основной вариант", response.body
    assert_no_match "Мутация A", response.body
    assert_match "Мутация B", response.body
  end

  test "result redirects to new creation if all variants failed" do
    generation = create(:generation, status: "failed")
    create(:generation_variant, :main, :failed, generation: generation)

    get result_creation_path(generation.design)
    assert_redirected_to new_creation_path
    assert_equal "Генерация не удалась. Попробуйте ещё раз.", flash[:alert]
  end

  # --- show ---

  test "show redirects to result" do
    generation = create(:generation, status: "succeeded")
    create(:generation_variant, :main, :succeeded, generation: generation)

    get creation_path(generation.design)
    assert_redirected_to result_creation_path(generation.design)
  end
end
