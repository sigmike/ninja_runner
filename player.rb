class Rubygame::Rect
  def inside?(other)
    if other.is_a? Rubygame::Screen
      inside?(Rubygame::Rect.new(0, 0, other.size[0], other.size[1]))
    else
      other.contain?(self)
    end
  end
end

# Player représente le joueur dans le jeu

class Player
  attr_accessor :position, :direction, :movement_lifetime, :target
  
  def initialize(game)
    @game = game
    @position = Rubygame::Rect.new(0, 0, 0, 0)
    @target = Rubygame::Rect.new(0, 0, 0, 0)
  end

  # détermine le déplacement en fonction de la direction
  
  def next_move
    {
      :right => [1, 0],
      :left => [-1, 0],
      :up => [0, -1],
      :down => [0, 1],
    }[@direction]
  end
    
  # applique la direction pour une case
  
  def apply_direction(with_rope_effect = true)
    r = with_rope_effect ? rope_effect_up : 0
    d = next_move
    @position.x += d[0]
    @position.y += d[1] + r
    @position.x %= @game.width
    @position.y %= @game.height
  end
  
  # demande au jeu si la case est accéssible
  
  def can_move?
    x = (@position.x + next_move[0]) % @game.width
    y = (@position.y + next_move[1] + rope_effect_up) % @game.height

    @game.accessible?(x, y)
  end
  
  def rope_effect_up
    rope_effect_up = 0
    if @game.rope_active? && @direction != :up && @direction != :down
      rope_effect_up = @game.accroch_point_at_top? ? 1 : -1
    end
    rope_effect_up
  end
  
  # indique une direction
  
  def start_moving(direction, lifetime)
    @direction = direction
    @last_movement_lifetime = nil
    move(lifetime)
  end
  
  # enlève la direction

  def stop_moving
    @direction = nil
    @last_movement_lifetime = nil
  end
  
  # applique la direction en cours en passant par toutes les positions
  
  def move(lifetime)
    if @direction
      while (@last_movement_lifetime.nil? or lifetime >= @last_movement_lifetime + REPEAT_TIME) and can_move?
        apply_direction
        @last_movement_lifetime = lifetime # Que se passe-t-il si on ne peut pas aller sur la case ?
      end
    end
  end
  
  def x
    @position.x
  end
  
  def y
    @position.y
  end
end

