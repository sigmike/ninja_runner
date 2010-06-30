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
  attr_accessor :position_x, :position_y, :direction, :movement_lifetime
  
  def initialize(game)
    @game = game
    @position_x = 0
    @position_y = 0
    @vector_x = 0
    @vector_y = 0
    @velocity_x = 0
    @velocity_y = 0
    @last_movement_lifetime = 0
  end
  
  def direction
    if @vector_x >= 0
      :right
    else
      :left
    end
  end
  
  # applique la direction
  
  ACCEL = 10.0
  VELOCITY = 1000.0
  
  def apply_direction(time, with_rope_effect = true)
    time /= 1000.0
    r = with_rope_effect ? rope_effect_up : 0
    gravity = GRAVITY * CELL_SIZE / 1000 # px/ms

    accel_x = 0
    accel_y = gravity
    
    @velocity_x = @vector_x * time
    @velocity_y = (1 + @vector_y) * time
    
    @position_x += @velocity_x * time * VELOCITY
    @position_y += @velocity_y * time * VELOCITY
    @position_x %= @game.width * CELL_SIZE
    @position_y %= @game.height * CELL_SIZE
  end
  
  # demande au jeu si la case est accéssible
  
  def can_move?
    #x = (@position_x + next_move[0]) % @game.width
    #y = (@position_y + next_move[1] + rope_effect_up) % @game.height

    #@game.accessible?(x, y)
    true
  end
  
  def rope_effect_up
    rope_effect_up = 0
    if @game.rope.active? && @direction != :up && @direction != :down
      rope_effect_up = @game.rope.accroch_point_at_top? ? 1 : -1
    end
    rope_effect_up
  end
  
  # indique une direction
  
  def start_moving(direction)
    @vector_y += direction == :up ? -1 : 1 if direction == :up || direction == :down
    @vector_x += direction == :left ? -1 : 1 if direction == :right || direction == :left
  end
  
  # enlève la direction

  def stop_moving(direction)
    @vector_y -= direction == :up ? -1 : 1 if direction == :up || direction == :down
    @vector_x -= direction == :left ? -1 : 1 if direction == :right || direction == :left
  end
  
  # applique la direction en cours en passant par toutes les positions
  
  def move(lifetime)
    dt = lifetime - @last_movement_lifetime
    apply_direction dt
    @game.catch_item(lifetime)
    @last_movement_lifetime = lifetime
  end
  
  def x
    @position_x
  end
  
  def y
    @position_y
  end
  
  def grid_x
    @position_x / CELL_SIZE
  end
  
  def grid_y
    @position_y / CELL_SIZE
  end
end

