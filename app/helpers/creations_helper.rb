module CreationsHelper
  def variant_label(variant)
    case variant.kind
    when "main" then "Основной вариант"
    when "mutation_a" then "Мутация A"
    when "mutation_b" then "Мутация B"
    else variant.kind
    end
  end
end
