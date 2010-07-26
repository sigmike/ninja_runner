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
    
    dx = x1 - x0
    dy = y1 - y0
    
    max = [dx.abs, dy.abs].max
    
    if (max != 0)
      step_x = dx / max
      step_y = dy / max
      
      # current x and y
      cx = x0
      cy = y0
      collided = false
    
      #puts "cx : #{cx}  ###  x1 : #{x1} ||| cy : #{cy}  ###  y1 : #{y1}"
    
      dirx = (x1 > x0) ? 1 : -1
      diry = (y1 > y0) ? 1 : -1
      if (dirx > 0) && (diry > 0)
	test_end = proc { (cx < x1) && (cy < y1) }
      elsif (dirx > 0) && (diry < 0)
	test_end = proc { (cx < x1) && (cy > y1) }
      elsif (dirx < 0) && (diry > 0)
	test_end = proc { (cx > x1) && (cy < y1) }
      else
	test_end = proc { (cx > x1) && (cy > y1) }
      end
      
      while test_end.call
	cx += step_x
	cy += step_y
	if collide?(cx, cy)
	  collided = true
	  cx -= step_x
	  cy -= step_y
	  break
	end
      end
      
      if !collided
	step_x = x1 - cx
	step_y = y1 - cy
	cx += step_x
	cy += step_y
	if collide?(cx, cy)
	  puts 'collided ici'
	  collided = true
	  cx -= step_x
	  cy -= step_y
	end
      else
	puts 'collided'
      end

      @position_x = cx
      @position_y = cy
      
      @position_x %= @game.width * CELL_SIZE
      @position_y %= @game.height * CELL_SIZE
    else
      puts "no max, sorry"
    end
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

