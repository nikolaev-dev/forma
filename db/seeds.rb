# Admin user
admin = User.find_or_create_by!(email: "admin@forma.ru") do |u|
  u.name = "Admin"
  u.role = "admin"
  u.status = "active"
end
puts "Admin user: #{admin.email} (id: #{admin.id})"

# App settings
settings = {
  "generation_daily_limit"       => { "value" => 10 },
  "generation_pass_price_cents"  => { "value" => 10000 },
  "generation_pass_duration_hours" => { "value" => 24 },
  "max_tags_per_generation"      => { "value" => 5 },
  "notebook_base_price_cents"    => { "value" => 259900 },
  "notebook_pro_price_cents"     => { "value" => 319900 },
  "notebook_elite_price_cents"   => { "value" => 899900 }
}

settings.each do |key, val|
  AppSetting.find_or_create_by!(key: key) do |s|
    s.value = val
    s.updated_by_user = admin
  end
end
puts "App settings: #{AppSetting.count} records"

# --- Tag Categories ---
categories_data = [
  { name: "Страны", slug: "countries", position: 1 },
  { name: "Сезоны", slug: "seasons", position: 2 },
  { name: "Стихии", slug: "elements", position: 3 },
  { name: "Материалы", slug: "materials", position: 4 },
  { name: "Настроения", slug: "moods", position: 5 },
  { name: "Цвета", slug: "colors", position: 6 },
  { name: "Эпохи", slug: "eras", position: 7 },
  { name: "Природа", slug: "nature", position: 8 }
]

categories = {}
categories_data.each do |data|
  cat = TagCategory.find_or_create_by!(slug: data[:slug]) do |c|
    c.name = data[:name]
    c.position = data[:position]
  end
  categories[data[:slug]] = cat
end
puts "Tag categories: #{TagCategory.count} records"

# --- Tags ---
tags_data = {
  "countries" => [
    { name: "Япония", slug: "japan" },
    { name: "Италия", slug: "italy" },
    { name: "Франция", slug: "france" },
    { name: "Норвегия", slug: "norway" },
    { name: "Индия", slug: "india" },
    { name: "Марокко", slug: "morocco" },
    { name: "Мексика", slug: "mexico" },
    { name: "Греция", slug: "greece" }
  ],
  "seasons" => [
    { name: "Весна", slug: "spring" },
    { name: "Лето", slug: "summer" },
    { name: "Осень", slug: "autumn" },
    { name: "Зима", slug: "winter" }
  ],
  "elements" => [
    { name: "Огонь", slug: "fire" },
    { name: "Вода", slug: "water" },
    { name: "Воздух", slug: "air" },
    { name: "Земля", slug: "earth" }
  ],
  "materials" => [
    { name: "Мрамор", slug: "marble" },
    { name: "Дерево", slug: "wood" },
    { name: "Золото", slug: "gold" },
    { name: "Серебро", slug: "silver" },
    { name: "Бронза", slug: "bronze" },
    { name: "Керамика", slug: "ceramic" },
    { name: "Шёлк", slug: "silk" },
    { name: "Бархат", slug: "velvet" }
  ],
  "moods" => [
    { name: "Спокойствие", slug: "calm" },
    { name: "Энергия", slug: "energy" },
    { name: "Романтика", slug: "romance" },
    { name: "Минимализм", slug: "minimalism" },
    { name: "Роскошь", slug: "luxury" },
    { name: "Уют", slug: "cozy" },
    { name: "Дерзость", slug: "bold" },
    { name: "Ностальгия", slug: "nostalgia" }
  ],
  "colors" => [
    { name: "Терракота", slug: "terracotta" },
    { name: "Индиго", slug: "indigo" },
    { name: "Изумруд", slug: "emerald" },
    { name: "Бордо", slug: "bordeaux" },
    { name: "Слоновая кость", slug: "ivory" },
    { name: "Чёрный", slug: "black" },
    { name: "Пыльная роза", slug: "dusty-rose" },
    { name: "Небесный", slug: "sky-blue" }
  ],
  "eras" => [
    { name: "Ар-деко", slug: "art-deco" },
    { name: "Баухаус", slug: "bauhaus" },
    { name: "Ренессанс", slug: "renaissance" },
    { name: "Футуризм", slug: "futurism" },
    { name: "Викторианство", slug: "victorian" },
    { name: "Модерн", slug: "modern" }
  ],
  "nature" => [
    { name: "Горы", slug: "mountains" },
    { name: "Океан", slug: "ocean" },
    { name: "Лес", slug: "forest" },
    { name: "Пустыня", slug: "desert" },
    { name: "Цветы", slug: "flowers" },
    { name: "Звёзды", slug: "stars" }
  ]
}

tags_data.each do |category_slug, tags|
  category = categories[category_slug]
  tags.each do |tag_data|
    Tag.find_or_create_by!(slug: tag_data[:slug]) do |t|
      t.name = tag_data[:name]
      t.tag_category = category
    end
  end
end
puts "Tags: #{Tag.count} records"

# --- Styles ---
styles_data = [
  { name: "Японский минимализм", slug: "japanese-minimalism", description: "Чистые линии, wabi-sabi эстетика, природные текстуры",
    tag_slugs: %w[japan minimalism calm], generation_preset: { style_prompt: "Japanese minimalist wabi-sabi aesthetic, clean lines, natural textures, muted earth tones" } },
  { name: "Итальянский мрамор", slug: "italian-marble", description: "Элегантный мрамор, золотые прожилки, классическая роскошь",
    tag_slugs: %w[italy marble luxury gold], generation_preset: { style_prompt: "Italian marble texture with golden veins, elegant classical luxury aesthetic" } },
  { name: "Скандинавский уют", slug: "scandinavian-cozy", description: "Хюгге-атмосфера, мягкие тона, текстура дерева",
    tag_slugs: %w[norway cozy wood minimalism], generation_preset: { style_prompt: "Scandinavian hygge cozy aesthetic, soft warm tones, light wood textures, minimal" } },
  { name: "Французский ар-деко", slug: "french-art-deco", description: "Геометрические паттерны, золото и чёрный, glamour 1920-х",
    tag_slugs: %w[france art-deco gold black luxury], generation_preset: { style_prompt: "French Art Deco geometric patterns, gold and black, 1920s glamour elegance" } },
  { name: "Марокканская керамика", slug: "moroccan-ceramic", description: "Зелличе-узоры, яркие цвета, ручная работа",
    tag_slugs: %w[morocco ceramic terracotta bold], generation_preset: { style_prompt: "Moroccan zellige ceramic patterns, vibrant colors, handcrafted tile textures" } },
  { name: "Ночное небо", slug: "night-sky", description: "Звёздное небо, глубокий индиго, космическая тишина",
    tag_slugs: %w[stars indigo calm], generation_preset: { style_prompt: "Deep night sky, stars and constellations, cosmic indigo, serene celestial beauty" } },
  { name: "Весенний сад", slug: "spring-garden", description: "Цветение сакуры, нежные лепестки, пробуждение природы",
    tag_slugs: %w[spring flowers dusty-rose romance], generation_preset: { style_prompt: "Spring garden cherry blossoms, delicate petals, soft pink and green, romantic nature" } },
  { name: "Пустыня на закате", slug: "desert-sunset", description: "Терракотовые дюны, закатное золото, бескрайний горизонт",
    tag_slugs: %w[desert terracotta gold energy], generation_preset: { style_prompt: "Desert sunset landscape, terracotta sand dunes, golden light, vast horizon, warm energy" } },
  { name: "Бархатная ночь", slug: "velvet-night", description: "Тёмный бархат, глубокие тона, тактильная роскошь",
    tag_slugs: %w[velvet bordeaux luxury nostalgia], generation_preset: { style_prompt: "Dark velvet texture, deep bordeaux and navy, tactile luxury, nostalgic richness" } },
  { name: "Горный туман", slug: "mountain-mist", description: "Утренний туман в горах, мягкие силуэты, прохлада",
    tag_slugs: %w[mountains water calm sky-blue], generation_preset: { style_prompt: "Mountain morning mist, soft silhouettes, cool blue tones, serene landscape, peaceful" } }
]

styles_data.each do |data|
  style = Style.find_or_create_by!(slug: data[:slug]) do |s|
    s.name = data[:name]
    s.description = data[:description]
    s.status = "published"
    s.generation_preset = data[:generation_preset]
  end

  data[:tag_slugs].each do |tag_slug|
    tag = Tag.find_by(slug: tag_slug)
    next unless tag
    StyleTag.find_or_create_by!(style: style, tag: tag)
  end
end
puts "Styles: #{Style.count} records (with #{StyleTag.count} tag associations)"

# --- Catalog Sections ---
editorial = CatalogSection.find_or_create_by!(slug: "forma-editorial") do |s|
  s.name = "Редакция FORMA"
  s.section_type = "editorial"
  s.position = 1
end

popular = CatalogSection.find_or_create_by!(slug: "popular-today") do |s|
  s.name = "Популярное сегодня"
  s.section_type = "popular"
  s.position = 2
end

CatalogSection.find_or_create_by!(slug: "new-arrivals") do |s|
  s.name = "Новинки"
  s.section_type = "new"
  s.position = 3
end

# Add published styles to editorial section
Style.published.each_with_index do |style, idx|
  CatalogItem.find_or_create_by!(catalog_section: editorial, item_type: "Style", item_id: style.id) do |ci|
    ci.position = idx
  end
end
puts "Catalog sections: #{CatalogSection.count}, items: #{CatalogItem.count}"

# =============================================================================
# VISUAL DEMO DATA — cover images, popularity scores, completed generation
# =============================================================================
require "chunky_png"
Rails.application.config.active_job.queue_adapter = :inline

# Палитра цветов для стилей (обложки-заглушки с градиентами и фигурами)
STYLE_PALETTES = {
  "japanese-minimalism"  => { bg: [245, 240, 235], fg: [180, 160, 140], accent: [120, 100, 80]  },
  "italian-marble"       => { bg: [245, 245, 250], fg: [200, 190, 200], accent: [200, 170, 80]  },
  "scandinavian-cozy"    => { bg: [250, 245, 240], fg: [210, 195, 175], accent: [180, 160, 130] },
  "french-art-deco"      => { bg: [30, 30, 35],    fg: [200, 170, 80],  accent: [255, 215, 100] },
  "moroccan-ceramic"     => { bg: [220, 160, 100], fg: [60, 120, 120],  accent: [200, 80, 60]   },
  "night-sky"            => { bg: [15, 15, 45],    fg: [40, 40, 80],    accent: [255, 255, 200] },
  "spring-garden"        => { bg: [250, 240, 245], fg: [220, 180, 190], accent: [180, 220, 160] },
  "desert-sunset"        => { bg: [230, 170, 100], fg: [200, 120, 60],  accent: [250, 200, 80]  },
  "velvet-night"         => { bg: [50, 20, 35],    fg: [100, 40, 60],   accent: [180, 80, 100]  },
  "mountain-mist"        => { bg: [200, 215, 230], fg: [150, 170, 190], accent: [100, 130, 160] }
}

POPULARITY_SCORES = {
  "japanese-minimalism" => 4.8, "italian-marble" => 4.5, "scandinavian-cozy" => 4.2,
  "french-art-deco" => 4.7, "moroccan-ceramic" => 3.9, "night-sky" => 4.6,
  "spring-garden" => 4.1, "desert-sunset" => 3.8, "velvet-night" => 4.3,
  "mountain-mist" => 4.0
}

def generate_cover_png(palette, width: 360, height: 480)
  bg = palette[:bg]
  fg = palette[:fg]
  accent = palette[:accent]

  png = ChunkyPNG::Image.new(width, height, ChunkyPNG::Color.rgb(*bg))

  # Gradient background — vertical
  height.times do |y|
    ratio = y.to_f / height
    r = (bg[0] * (1 - ratio * 0.3) + fg[0] * ratio * 0.3).to_i.clamp(0, 255)
    g = (bg[1] * (1 - ratio * 0.3) + fg[1] * ratio * 0.3).to_i.clamp(0, 255)
    b = (bg[2] * (1 - ratio * 0.3) + fg[2] * ratio * 0.3).to_i.clamp(0, 255)
    color = ChunkyPNG::Color.rgb(r, g, b)
    width.times { |x| png[x, y] = color }
  end

  # Geometric shapes
  fg_color = ChunkyPNG::Color.rgb(*fg)
  accent_color = ChunkyPNG::Color.rgb(*accent)

  # Large circle
  cx, cy, cr = width / 2, height / 3, [width, height].min / 4
  (cy - cr..cy + cr).each do |y|
    next if y < 0 || y >= height
    (cx - cr..cx + cr).each do |x|
      next if x < 0 || x >= width
      dist = Math.sqrt((x - cx)**2 + (y - cy)**2)
      if dist <= cr
        alpha = [ 1.0 - (dist / cr) * 0.5, 0.0 ].max
        base = png[x, y]
        br = ChunkyPNG::Color.r(base)
        bg_val = ChunkyPNG::Color.g(base)
        bb = ChunkyPNG::Color.b(base)
        nr = (br * (1 - alpha * 0.6) + fg[0] * alpha * 0.6).to_i.clamp(0, 255)
        ng = (bg_val * (1 - alpha * 0.6) + fg[1] * alpha * 0.6).to_i.clamp(0, 255)
        nb = (bb * (1 - alpha * 0.6) + fg[2] * alpha * 0.6).to_i.clamp(0, 255)
        png[x, y] = ChunkyPNG::Color.rgb(nr, ng, nb)
      end
    end
  end

  # Horizontal accent stripe
  stripe_y = (height * 0.6).to_i
  stripe_h = (height * 0.04).to_i
  (stripe_y..stripe_y + stripe_h).each do |y|
    next if y >= height
    width.times do |x|
      margin = width * 0.15
      next if x < margin || x > width - margin
      png[x, y] = accent_color
    end
  end

  # Small dots pattern
  dot_r = 3
  (0..width).step(24) do |dx|
    (height * 0.7).to_i.step(height - 20, 24) do |dy|
      ((dy - dot_r)..(dy + dot_r)).each do |y|
        next if y < 0 || y >= height
        ((dx - dot_r)..(dx + dot_r)).each do |x|
          next if x < 0 || x >= width
          png[x, y] = accent_color if Math.sqrt((x - dx)**2 + (y - dy)**2) <= dot_r
        end
      end
    end
  end

  png.to_blob(:fast_rgb)
end

def generate_variant_png(palette, variant_shift, width: 480, height: 640)
  shifted = {
    bg: palette[:bg].map { |c| (c + variant_shift).clamp(0, 255) },
    fg: palette[:fg].map { |c| (c + variant_shift * 2).clamp(0, 255) },
    accent: palette[:accent]
  }
  generate_cover_png(shifted, width: width, height: height)
end

# Attach cover images + set popularity scores
puts "Generating cover images..."
Style.find_each do |style|
  palette = STYLE_PALETTES[style.slug]
  next unless palette

  unless style.cover_image.attached?
    blob = generate_cover_png(palette)
    style.cover_image.attach(
      io: StringIO.new(blob),
      filename: "#{style.slug}-cover.png",
      content_type: "image/png"
    )
    puts "  ✓ Cover: #{style.name}"
  end

  score = POPULARITY_SCORES[style.slug]
  style.update_columns(popularity_score: score) if score && style.popularity_score != score
end

# --- Completed generation (для демо страницы результата) ---
puts "Creating demo generation..."

demo_style = Style.find_by(slug: "japanese-minimalism")
if demo_style
  design = Design.find_or_create_by!(slug: "demo-japanese") do |d|
    d.user = admin
    d.style = demo_style
    d.title = "Японский минимализм — демо"
    d.base_prompt = "Минималистичный блокнот в японском стиле, чистые линии, натуральные текстуры"
    d.visibility = "public"
    d.moderation_status = "ok"
  end

  design.create_prompt!(current_text: design.base_prompt) unless design.prompt

  generation = Generation.find_or_create_by!(design: design, source: "create") do |g|
    g.user = admin
    g.status = "succeeded"
    g.provider = "test"
    g.preset_snapshot = demo_style.generation_preset
    g.tags_snapshot = { tags: %w[japan minimalism calm] }
    g.started_at = 30.seconds.ago
    g.finished_at = Time.current
  end

  palette = STYLE_PALETTES["japanese-minimalism"]

  [
    { kind: "main",       shift: 0,   summary: nil },
    { kind: "mutation_a", shift: -15, summary: "Добавлен тег: Дерево" },
    { kind: "mutation_b", shift: 20,  summary: "Замена: Спокойствие → Энергия" }
  ].each do |vdata|
    variant = GenerationVariant.find_or_create_by!(generation: generation, kind: vdata[:kind]) do |v|
      v.status = "succeeded"
      v.composed_prompt = "#{demo_style.generation_preset['style_prompt']}, notebook cover design"
      v.mutation_summary = vdata[:summary]
    end

    unless variant.preview_image.attached?
      blob = generate_variant_png(palette, vdata[:shift])
      variant.preview_image.attach(
        io: StringIO.new(blob),
        filename: "variant-#{vdata[:kind]}.png",
        content_type: "image/png"
      )
      puts "  ✓ Variant: #{vdata[:kind]}"
    end
  end

  puts "Demo generation: design=#{design.slug}, generation_id=#{generation.id}"
  puts "  View result at: /creations/#{design.id}/result"
end

puts "\n✓ Visual demo data complete!"

# =============================================================================
# FILLINGS — наполнения блокнота
# =============================================================================
fillings_data = [
  { name: "Клетка",   slug: "grid",  filling_type: "grid" },
  { name: "Линейка",  slug: "ruled", filling_type: "ruled" },
  { name: "Точки",    slug: "dot",   filling_type: "dot" },
  { name: "Пустые",   slug: "blank", filling_type: "blank" }
]

fillings_data.each do |data|
  Filling.find_or_create_by!(slug: data[:slug]) do |f|
    f.name = data[:name]
    f.filling_type = data[:filling_type]
  end
end
puts "Fillings: #{Filling.count} records"

# =============================================================================
# NOTEBOOK SKUs — комплектации
# =============================================================================
skus_data = [
  { code: "base",  name: "FORMA Base",  price_cents: 259900,
    specs: { cover: "Софт-тач ламинация", pages: "80 листов", format: "A5" } },
  { code: "pro",   name: "FORMA Pro",   price_cents: 319900,
    specs: { cover: "Софт-тач + тиснение", pages: "120 листов", format: "A5", extras: "Ленточка-закладка" } },
  { code: "elite", name: "FORMA Elite", price_cents: 899900,
    specs: { cover: "Итальянская кожа", pages: "160 листов", format: "A5", extras: "Закладка, резинка, DNA Card" } }
]

skus_data.each do |data|
  NotebookSku.find_or_create_by!(code: data[:code]) do |s|
    s.name = data[:name]
    s.price_cents = data[:price_cents]
    s.specs = data[:specs]
  end
end
puts "Notebook SKUs: #{NotebookSku.count} records"
