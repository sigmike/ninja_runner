class Rubygame::Rect
  def inside?(other)
    if other.is_a? Rubygame::Screen
      inside?(Rubygame::Rect.new(0, 0, other.size[0], other.size[1]))
    else
      other.contain?(self)
    end
  end
end

class Player
  attr_accessor :position, :direction, :movement_lifetime, :target
  
  def initialize(game)
    @game = game
    @position = Rubygame::Rect.new(0, 0, 0, 0)
    @target = Rubygame::Rect.new(0, 0, 0, 0)
  end

  def next_move
    {
      :right => [1, 0],
      :left => [-1, 0],
      :up => [0, -1],
      :down => [0, 1],
    }[@direction]
  end
  
  def apply_direction
    d = next_move
    @position.x += d[0]
    @position.y += d[1]
    @position.x %= @game.width
    @position.y %= @game.height
  end
  
  def can_move?
    x = (@position.x + next_move[0]) % @game.width
    y = (@position.y + next_move[1]) % @game.height
    @game.accessible?(x, y)
  end
  
  def start_moving(direction, lifetime)
    @direction = direction
    @last_movement_lifetime = nil
    move(lifetime)
  end

  def stop_moving
    @direction = nil
    @last_movement_lifetime = nil
  end
  
  def move(lifetime)
    if @direction
      while (@last_movement_lifetime.nil? or lifetime >= @last_movement_lifetime + REPEAT_TIME) and can_move?
        apply_direction
        @last_movement_lifetime = lifetime
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

