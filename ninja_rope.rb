require 'rubygame'
Rubygame.init

ITEM_LIFETIME = 2000
REPEAT_TIME = 200

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
  attr_accessor :position, :direction
  
  def initialize(game)
    @game = game
    @position = Rubygame::Rect.new(0, 0, 0, 0)
  end
  
  def apply_direction
    d = {
      :right => [1, 0],
      :left => [-1, 0],
      :up => [0, -1],
      :down => [0, 1],
    }[@direction]
    @position.x += d[0]
    @position.y += d[1]
    @position.x %= @game.width
    @position.y %= @game.height
  end
  
  def start_moving(direction, lifetime)
    @direction = direction
    apply_direction
    @movement_lifetime = lifetime
  end
  
  def stop_moving
    @direction = nil
    @movement_lifetime = nil
  end
  
  def move(lifetime)
    if @direction
      while lifetime >= @movement_lifetime + REPEAT_TIME
        apply_direction
        @movement_lifetime += REPEAT_TIME
      end
    end
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
  attr_accessor :life
  
  def initialize birthtime
    @birthtime = birthtime
    @life = 255
  end
  
  def update current_time
    @life = (ITEM_LIFETIME - (current_time - @birthtime)) * 255 / ITEM_LIFETIME
    @alive = (current_time - @birthtime) <= ITEM_LIFETIME
  end
  
  def alive?
    @alive
  end
end

class Game
  attr_accessor :player, :screen, :scenario, :clock, :grid
  attr_reader :width, :height
  
  def start
    @player = Player.new(self)
    @clock = Rubygame::Clock.new
    @width = 40
    @height = 24
    @grid = Array.new(@width) { Array.new(@height) }
    @screen = Rubygame::Screen.new([@width * 24, @height * 24])
    @music = Rubygame::Music.load "music/2 - Please.mp3"
    @music.play
  end
  
  def grid_size
    [@width, @height]
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
  
  def key_direction(key)
    case key
    when Rubygame::K_RIGHT
      :right
    when Rubygame::K_LEFT
      :left
    when Rubygame::K_UP
      :up
    when Rubygame::K_DOWN
      :down
    end
  end
  
  def process_events(lifetime)
    events = Rubygame.fetch_sdl_events
    events.each do |event|
      case event
      when Rubygame::KeyDownEvent
        case event.key
        when Rubygame::K_RIGHT, Rubygame::K_LEFT, Rubygame::K_UP, Rubygame::K_DOWN
          @player.start_moving(key_direction(event.key), lifetime)
        end
      when Rubygame::KeyUpEvent
        case event.key
        when Rubygame::K_ESCAPE
          @end = true
        when Rubygame::K_RIGHT, Rubygame::K_LEFT, Rubygame::K_UP, Rubygame::K_DOWN
          @player.stop_moving if @player.direction == key_direction(event.key)
        end
      when Rubygame::MouseMotionEvent
        if event.buttons.include?(Rubygame::MOUSE_LEFT)
          x, y = event.pos.map { |n| n / 24 }
          cell = [x, y]
          if cell != @last_mouse_cell
            @last_mouse_cell = cell
            puts "#{lifetime} #{x},#{y}"
          end
        end
      when Rubygame::MouseDownEvent
        x, y = event.pos.map { |n| n / 24 }
        cell = [x, y]
        puts "#{lifetime} #{x},#{y}"
      end
    end
  end
  
  def process_game_events(lifetime)
    loop do
      break if @game_events.nil?
      break if @game_events.empty?
      break if @game_events.first.time > lifetime
      event = @game_events.shift
      @grid[event.x][event.y] = Item.new event.time
    end
  end
  
  def update_grid(lifetime)
    each_item do |x, y, item|
      item.update lifetime
      unless item.alive?
        @grid[x][y] = nil
      end
    end
  end
  
  def update_player(lifetime)
    @player.move(lifetime)
  end

  def update
    @screen.fill([0,0,0])
  
    lifetime = @clock.lifetime
    
    process_events(lifetime)
    process_game_events(lifetime)
    
    update_grid(lifetime)
    update_player(lifetime)

    draw
  end
  
  def draw
    each_item do |x, y, item|
      draw_item(x, y, item)
    end
    draw_player
    @screen.update
  end
  
  def draw_player
    sprite_size = 24
    surface = Rubygame::Surface.load_image('gfx/ninja.png').to_display
    position = @player.position.dup
    position.x *= 24
    position.y *= 24
    surface.blit(@screen, position)
  end
  
  def draw_item(x, y, item)
    sprite_size = 24
    surface = Rubygame::Surface.load_image('gfx/bonus.png').to_display
    surface.set_alpha item.life
    surface.blit(@screen, [x * sprite_size, y * sprite_size])
  end
  
  def item(x, y)
    @grid[x][y]
  end
  
  def end?
    @end
  end
end
