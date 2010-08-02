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
  
  def apply_direction(time, with_rope_effect = true)
    r = with_rope_effect ? rope_effect_up : 0
    gravity = 0 #GRAVITY

    @velocity_x = @vector_x * VELOCITY * CELL_SIZE
    @velocity_y = (gravity + @vector_y * VELOCITY) * CELL_SIZE
    
    new_position_x = @position_x + @velocity_x * time 
    new_position_y = @position_y + @velocity_y * time
    
    x0 = @position_x
    y0 = @position_y
    x1 = new_position_x
    y1 = new_position_y
    
    loop do
      break if x0 == x1 and y0 == y1
      
      dx = x1 - x0
      dy = y1 - y0
      
      end_cell_x = (x1 / CELL_SIZE).to_i
      end_cell_y = (y1 / CELL_SIZE).to_i
      
      cell_x = (x0 / CELL_SIZE).to_i
      cell_y = (y0 / CELL_SIZE).to_i
      
      vertical_left = cell_x * CELL_SIZE
      vertical_right = (cell_x + 1) * CELL_SIZE - EPSILON
      horizontal_top = cell_y * CELL_SIZE
      horizontal_bottom = (cell_y + 1) * CELL_SIZE - EPSILON
    
      unless @game.accessible?(cell_x, cell_y)
	break
      end
      
      if end_cell_x == cell_x and end_cell_y == cell_y
	x0 = x1
	y0 = y1
      else
	vertical_right_y = y0 + (x0 - vertical_right) * dy / dx
	vertical_left_y = y0 + (x0 - vertical_left) * dy / dx
	horizontal_top_x = x0 + (y0 - horizontal_top ) * dx / dy
	horizontal_bottom_x = x0 + (y0 - horizontal_bottom ) * dx / dy
	  
	if dx < 0 and vertical_left_y > horizontal_top and vertical_left_y < horizontal_bottom
	  next_cell_x = cell_x - 1
	  next_cell_y = cell_y
	  if @game.accessible?(next_cell_x, next_cell_y)
	    x0 = vertical_left - EPSILON
	    y0 = vertical_left_y
	  else
	    x0 = x1 = vertical_left
	    y0 = y1 = vertical_left_y
	  end
	  
	elsif dx > 0 and vertical_right_y > horizontal_top and vertical_right_y < horizontal_bottom
	  next_cell_x = cell_x + 1
	  next_cell_y = cell_y
	  if @game.accessible?(next_cell_x, next_cell_y)
	    x0 = vertical_right + EPSILON
	    y0 = vertical_right_y
	  else
	    x0 = x1 = vertical_right
	    y0 = y1 = vertical_right_y
	  end
	  
	elsif dy > 0 and horizontal_bottom_x > vertical_left and horizontal_bottom_x < vertical_right
	  next_cell_x = cell_x
	  next_cell_y = cell_y + 1
	  if @game.accessible?(next_cell_x, next_cell_y)
	    x0 = horizontal_bottom_x
	    y0 = horizontal_bottom + EPSILON
	  else
	    x0 = x1 = horizontal_bottom_x
	    y0 = y1 = horizontal_bottom
	  end
	  
	elsif dy < 0 and horizontal_top_x > vertical_left and horizontal_top_x < vertical_right
	  next_cell_x = cell_x
	  next_cell_y = cell_y - 1
	  if @game.accessible?(next_cell_x, next_cell_y)
	    x0 = horizontal_top_x
	    y0 = horizontal_top - EPSILON
	  else
	    x0 = x1 = horizontal_top_x
	    y0 = y1 = horizontal_top
	  end
	  
	else
	  p "diagonale"
	  x0 = x1
	  y0 = y1
	end
      end
    end
    
    @position_x = x0
    @position_y = y0
    
    @position_x %= @game.width * CELL_SIZE
    @position_y %= @game.height * CELL_SIZE
  end
  
  def collide?(x, y)
    x = (x / CELL_SIZE).round % @game.width
    y = (y / CELL_SIZE).round % @game.height

    !@game.accessible?(x, y)
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

