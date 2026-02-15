class AddTierToGenerationVariants < ActiveRecord::Migration[8.0]
  def change
    add_column :generation_variants, :tier, :string

    # Replace the old unique index [generation_id, kind] with two partial indexes:
    # 1. User generations (tier IS NULL): unique on [generation_id, kind]
    # 2. Training pipeline (tier IS NOT NULL): unique on [generation_id, kind, tier]
    remove_index :generation_variants, [:generation_id, :kind]

    add_index :generation_variants, [:generation_id, :kind],
      unique: true,
      where: "tier IS NULL",
      name: "idx_gen_variants_unique_kind_no_tier"

    add_index :generation_variants, [:generation_id, :kind, :tier],
      unique: true,
      where: "tier IS NOT NULL",
      name: "idx_gen_variants_unique_kind_with_tier"
  end
end
