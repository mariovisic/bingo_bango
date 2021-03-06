class GamesController < ApplicationController
  before_filter :prepare_game
  before_filter :prepare_participation

  def show
    @player_hue   = Player::Color.new(current_player.player).hue
    @first_player = @game.participations.first.player == current_player.player
  end

  def info
    render :json => { 
      :number     => @number = CurrentNumber.new(@game).number,
      :state      => @game_state.state,
      :game_start => @game_state.game_start_unix_time,
      :players    => @game.participations.map(&:player).flatten.map { |player| { :name => player.name, :color => Player::Color.new(player).to_s } }
    }
  end

  def mark_number
    if @game.drawn_numbers.include?(params[:number].to_i)
      head 200
    else
      head 422
    end
  end

  def bingo
    @game.with_lock do
      if @game_state.in_progress? && @participation.numbers.compact.all? { |number| @game.drawn_numbers.include?(number) }
        @game.update_attributes(winner: current_player.player)
      end
    end

    redirect_to game_path(@game)
  end

  private

  def prepare_game
    @game       = Game.find(params[:id] || params[:game_id])
    @game_state = GameState.new(@game)
  end

  def prepare_participation
    @participation ||= Participation.find_by(player_id: current_player.player.id, game_id: @game.id)
  end
end
