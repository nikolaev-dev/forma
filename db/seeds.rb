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
