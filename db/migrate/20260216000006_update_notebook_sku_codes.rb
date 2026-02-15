class UpdateNotebookSkuCodes < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      UPDATE notebook_skus SET code = 'core', name = 'FORMA Core' WHERE code = 'base';
      UPDATE notebook_skus SET code = 'signature', name = 'FORMA Signature' WHERE code = 'pro';
      UPDATE notebook_skus SET code = 'lux', name = 'FORMA Lux' WHERE code = 'elite';
    SQL
  end

  def down
    execute <<~SQL
      UPDATE notebook_skus SET code = 'base', name = 'FORMA Base' WHERE code = 'core';
      UPDATE notebook_skus SET code = 'pro', name = 'FORMA Pro' WHERE code = 'signature';
      UPDATE notebook_skus SET code = 'elite', name = 'FORMA Lux' WHERE code = 'lux';
    SQL
  end
end
