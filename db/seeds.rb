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
