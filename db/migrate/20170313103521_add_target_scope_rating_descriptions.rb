class AddTargetScopeRatingDescriptions < ActiveRecord::Migration[5.1]
  def change
    OrderTarget::RATINGS.each do |rating|
      add_column :target_scopes, "rating_#{rating}_description".to_sym, :string
    end
  end
end
