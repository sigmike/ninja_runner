require 'rubygame'
Rubygame.init

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
  attr_accessor :position
  
  def initialize
    @position = Rubygame::Rect.new(0, 0, 0, 0)
  end
end

class GameEvent
  attr_accessor :time, :x, :y
  def initialize(time, x, y)
    @time = time
    @x = x
    @y = y
  end
end

class Item
  def initialize birthtime
    @birthtime = birthtime
  end
  
  def update current_time
    @alive = (current_time - @birthtime) <= 1000
  end
  
  def alive?
    @alive
  end
end

class Game
  attr_accessor :player, :screen, :scenario, :clock
  
  def start
    @player = Player.new
    @clock = Rubygame::Clock.new
    @width = 100
    @height = 100
    @grid = Array.new(@width) { Array.new(@height) }
    @screen = Rubygame::Screen.new([800, 600])
  end
  
  def scenario=(scenario)
    @game_events = scenario.split("\n").map { |line|
      if line =~ /(\d+) (\d+),(\d+)/
        time = $1.to_i
        x = $2.to_i
        y = $3.to_i
        GameEvent.new(time, x, y)
      else
        raise "Invalid line: #{line.inspect}"
      end
    }
  end

  def each_cell
    @width.times { |x|
      @height.times { |y|
        item = @grid[x][y]
        yield x, y, item
      }
    }
  end
  
  def each_item
    each_cell do |x, y, item|
      yield x, y, item if item
    end
  end

  def update
    @screen.fill([0,0,0])
  
    lifetime = @clock.lifetime
    
    events = Rubygame.fetch_sdl_events
    events.each do |event|
      if event.is_a? Rubygame::KeyUpEvent
        #if event.key == Rubygame::K_ESCAPE
          @end = true
        #end
      end
    end
    
    loop do
      break if @game_events.nil?
      break if @game_events.empty?
      break if @game_events.first.time > lifetime
      event = @game_events.shift
      @grid[event.x][event.y] = Item.new event.time
    end
    
    each_item do |x, y, item|
      item.update lifetime
      unless item.alive?
        @grid[x][y] = nil
      end
    end

    each_item do |x, y, item|
      draw_item(x, y)
    end
    @screen.update
  end
  
  def draw_item(x, y)
    sprite_size = 24
    Rubygame::Surface.load_image('gfx/bonus.png').blit(@screen, [x * sprite_size, y * sprite_size])
  end
  
  def item(x, y)
    @grid[x][y]
  end
  
  def end?
    @end
  end
end
