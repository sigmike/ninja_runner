# Rope représente la corde du Player

class Rope

  attr_accessor :path
  
  def initialize(game, player)
    @game = game
    @player = player
  end
  
  def accroch point
    @accroch_point = Rubygame::Rect.new(point)
  end
  
  def accroch_point_at_left?
    @player.position.x > @accroch_point.x
  end
  
  def accroch_point_at_top?
    @player.position.y > @accroch_point.y
  end
  
  def active?
    @accroch_point
  end
  
  def deccroch
    @accroch_point = nil
  end
  
  def max_down?
    if active?
      result = true
      first_x = @accroch_point.x
      @path.each do |position|
        if position.x != first_x
          result = nil
          break
        end
      end
      result
    else
      nil
    end
  end
  
  def update
    @path = []
    if active?
      
      position = @accroch_point.dup

      while position != @player.position
        if @game.accessible?(@accroch_point.x, @accroch_point.y)
          deccroch
          break
        end
      
        new_position = position.dup
        
        if position.x < @player.position.x
          new_position.x = @game.accessible?(new_position.x + 1, new_position.y) ? new_position.x + 1 : new_position.x
        elsif position.x > @player.position.x
          new_position.x = @game.accessible?(new_position.x - 1, new_position.y) ? new_position.x - 1 : new_position.x
        end
        
        if position.y < @player.position.y
          new_position.y = @game.accessible?(new_position.x, new_position.y + 1) ? new_position.y + 1 : new_position.y
        elsif position.y > @player.position.y
          new_position.y = @game.accessible?(new_position.x, new_position.y - 1) ? new_position.y - 1 : new_position.y
        end
        
        if position != new_position
          position = new_position
        else
          deccroch
          break
        end
        @path << position.dup
      end
    end
  end
end

