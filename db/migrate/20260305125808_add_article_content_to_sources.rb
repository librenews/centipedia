class AddArticleContentToSources < ActiveRecord::Migration[8.1]
  def change
    add_column :sources, :article_title, :string
    add_column :sources, :article_author, :string
    add_column :sources, :article_content, :text
  end
end
