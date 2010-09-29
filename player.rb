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
  
  def same_signs?(a, b)
    (a < 0 and b < 0) or (a > 0 and b > 0)
  end
  
  def segment_collision(s1, s2)
    x1, y1, x2, y2 = s1.map { |x| x.to_f }
    x3, y3, x4, y4 = s2.map { |x| x.to_f }
    
    #long a1, a2, b1, b2, c1, c2 /* Coefficients of line eqns. */
    #long r1, r2, r3, r4         /* 'Sign' values */
    #long denom, offset, num     /* Intermediate values */

    #/* Compute a1, b1, c1, where line joining points 1 and 2
    # * is "a1 x  +  b1 y  +  c1  =  0".
    # */

    a1 = y2 - y1
    b1 = x1 - x2
    c1 = x2 * y1 - x1 * y2

    #/* Compute r3 and r4.
    # */

    r3 = a1 * x3 + b1 * y3 + c1
    r4 = a1 * x4 + b1 * y4 + c1

    #/* Check signs of r3 and r4.  If both point 3 and point 4 lie on
    # * same side of line 1, the line segments do not intersect.
    # */

    if ( r3 != 0 and r4 != 0 and same_signs?( r3, r4 ))
      return nil
    end

    #/* Compute a2, b2, c2 */

    a2 = y4 - y3
    b2 = x3 - x4
    c2 = x4 * y3 - x3 * y4

    #/* Compute r1 and r2 */

    r1 = a2 * x1 + b2 * y1 + c2
    r2 = a2 * x2 + b2 * y2 + c2

    #/* Check signs of r1 and r2.  If both point 1 and point 2 lie
    # * on same side of second line segment, the line segments do
    # * not intersect.
    # */

    if ( r1 != 0 and r2 != 0 and same_signs?( r1, r2 ))
      return nil
    end

    #/* Line segments intersect: compute intersection point. 
    # */

    denom = a1 * b2 - a2 * b1
    if ( denom == 0 )
      return nil # collinear
    end
    
    offset = denom < 0 ? - denom / 2 : denom / 2

    #/* The denom/2 is to get rounding instead of truncating.  It
    # * is added or subtracted to the numerator, depending upon the
    # * sign of the numerator.
    # */

    num = b1 * c2 - b2 * c1
    x = ( num < 0 ? num - offset : num + offset ) / denom

    num = a2 * c1 - a1 * c2
    y = ( num < 0 ? num - offset : num + offset ) / denom

    [x, y]
  end
  
  # applique la direction
  
  def apply_direction(time, with_rope_effect = true)
    gravity = 0 #GRAVITY

    @velocity_x = @vector_x * VELOCITY * CELL_SIZE
    @velocity_y = (gravity + @vector_y * VELOCITY) * CELL_SIZE
    
    new_position_x = @position_x + @velocity_x * time 
    new_position_y = @position_y + @velocity_y * time
    
    x0 = @position_x
    y0 = @position_y
    x1 = round(new_position_x)
    y1 = round(new_position_y)
    
    bricks = @game.brick_positions.map do |x, y|
      Rubygame::Rect.new x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE
    end
    
    # move_segment = x0, y0, x1, y1, offset
    move_offsets = [
      [ 0, 0,], # top - left
      [ CELL_SIZE, 0,], # top - right
      [ CELL_SIZE , + CELL_SIZE,], # bottom - right
      [ 0, + CELL_SIZE, ], # bottom - left
    ]
    
    move_segment_origin = [ x0, y0, x1, y1 ]
    
    collisions = []
    move_offsets.each do |move_offset|
      move_segment = move_segment_origin.dup
      
      # apply offset to move segments
      move_segment[0] += move_offset[0] # x0
      move_segment[1] += move_offset[1] # y0
      move_segment[2] += move_offset[0] # x1
      move_segment[3] += move_offset[1] # y1
    
      bricks.each do |rect|
        rx1 = rect.x - 1
        ry1 = rect.y - 1
        rx2 = rect.x + rect.width + 1
        ry2 = rect.y + rect.height + 1
        
        segments = [
          [rx1, ry1, rx2, ry1], # top
#           [rx2, ry1, rx2, ry2], # right
#           [rx1, ry2, rx2, ry2], # bottom
#           [rx1, ry1, rx1, ry2], # left
        ]
        
        collisions += segments.map do |rect_segment|
          collide = segment_collision(move_segment, rect_segment)
          if collide
            # to put collide like a top left corner
            collide[0] -= move_offset[0] + 0.5
            collide[1] -= move_offset[1] + 0.5
            
            # round values
            collide[0] = round(collide[0])
            collide[1] = round(collide[1])
          end
          collide
        end.compact
      end
    end
    
    unless collisions.empty?
      pp "---------------"
      pp @position_x.to_s + ", " + @position_y.to_s
      pp collisions
      x1, y1 = first_collide_point(collisions)
    end
    
    
    @position_x = round(x1)
    @position_y = round(y1)
    
    @position_x %= GRID_WIDTH_PX
    @position_y %= GRID_HEIGHT_PX
  end
  
  def round(number)
    (number * 100).ceil / 100.0
  end
  
  def first_collide_point collisions
    collisions.sort_by do |x, y|
      (@position_x - x)**2 + (@position_y - y)**2
    end.first
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

