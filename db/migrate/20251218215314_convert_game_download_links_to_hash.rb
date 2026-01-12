class ConvertGameDownloadLinksToHash < ActiveRecord::Migration[7.2]
  def change
    ActiveRecord::Base.connection.execute('SELECT id, download_links FROM games').each do |game_row|
      # if game_row['id'] == 2
      #   require 'pry'; binding.pry
      # end
      game = Game.find(game_row['id'])
      download_links = YAML.load(game_row['download_links'],
                                 permitted_classes: [
                                   ActiveSupport::HashWithIndifferentAccess,
                                   ActionController::Parameters,
                                   Symbol
                                 ])
      game.download_links = download_links.to_h
      game.download_links_will_change!
      game.save
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
