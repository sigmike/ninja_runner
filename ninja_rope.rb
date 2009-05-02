require 'rubygame'

class Rubygame::Rect
  def inside?(other)
    other.contain?(self)
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
end

class Game
  attr_accessor :player, :screen, :scenario, :clock
  
  def start
    @player = Player.new
    @screen = Rubygame::Rect.new(0, 0, 0, 0)
    @clock = Rubygame::Clock.new
    @grid = Array.new(100) { Array.new(100) }
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
  
  def update
    lifetime = @clock.lifetime
    
    events = Rubygame.fetch_sdl_events
    events.each do |event|
      if event.is_a? Rubygame::KeyUpEvent
        if event.key == Rubygame::K_ESCAPE
          @end = true
        end
      end
    end
    
    loop do
      break if @game_events.nil?
      break if @game_events.empty?
      break if @game_events.first.time > lifetime
      event = @game_events.pop
      @grid[event.x][event.y] = Item.new
    end
  end
  
  def item(x, y)
    @grid[x][y]
  end
  
  def end?
    @end
  end
end
