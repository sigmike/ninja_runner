require 'rubygame'
require 'rubygame/mediabag'
Rubygame.init

ITEM_LIFETIME = 2000
REPEAT_TIME = 50
CELL_SIZE = 24
GRAVITY = 1 # cell down per second
MILLISECONDS_PER_CELL = 1000.0 / GRAVITY

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
  attr_accessor :position, :direction, :movement_lifetime
  
  def initialize(game)
    @game = game
    @position = Rubygame::Rect.new(0, 0, 0, 0)
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
  
  def start_moving(direction, lifetime)
    @direction = direction
    #apply_direction
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
  
  def x
    @position.x
  end
  
  def y
    @position.y
  end
end

class GameEvent
  attr_accessor :time, :x, :y, :kind
  def initialize(time, x, y, kind)
    @time = time
    @x = x
    @y = y
    @kind = kind
  end
end

class Item
  attr_accessor :life, :kind
  
  def initialize birthtime, kind
    @birthtime = birthtime
    @life = 255
    @kind = kind
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
  attr_accessor :player, :screen, :scenario, :clock, :grid, :music_enabled, :score
  attr_reader :width, :height
  
  def start
    @player = Player.new(self)
    @clock = Rubygame::Clock.new
    Rubygame::TTF.setup
    @font = Rubygame::TTF.new 'fonts/arial.ttf', 23
    @width = 40
    @height = 24
    @score = 0
    @last_down_time = 0.0
    @grid = Array.new(@width) { Array.new(@height) }
    @record_grid = Array.new(@width) { Array.new(@height) }
    @screen = Rubygame::Screen.new([@width * CELL_SIZE, @height * CELL_SIZE])
    if @music_enabled
      @music = Rubygame::Music.load "music/2 - Please.mp3"
      @music.play
    end
    @media_bag = Rubygame::MediaBag.new
    @media_bag.load_image "gfx/ninja.png"
    @media_bag.load_image "gfx/bonus.png"
    @media_bag.load_image "gfx/brick.png"
  end
  
  def music_playing?
    @music
  end
  
  def grid_size
    [@width, @height]
  end
  
  def scenario=(scenario)
    @game_events = scenario.split("\n").map { |line|
      if line =~ /(\d+) (\d+),(\d+) (\w+)/
        time = $1.to_i
        x = $2.to_i
        y = $3.to_i
        type = $4
        GameEvent.new(time, x, y, type)
      else
        raise "Invalid line: #{line.inspect}"
      end
    }
  end

  def each_record_cell
    @width.times { |x|
      @height.times { |y|
        item = @record_grid[x][y]
        yield x, y, item
      }
    }
  end
  
  def each_record_item
    each_record_cell do |x, y, item|
      yield x, y, item if item
    end
  end

  def each_record_cell
    @width.times { |x|
      @height.times { |y|
        item = @record_grid[x][y]
        yield x, y, item
      }
    }
  end
  
  def each_record_item
    each_record_cell do |x, y, item|
      yield x, y, item if item
    end
  end

  def each_record_cell
    @width.times { |x|
      @height.times { |y|
        item = @record_grid[x][y]
        yield x, y, item
      }
    }
  end
  
  def each_record_item
    each_record_cell do |x, y, item|
      yield x, y, item if item
    end
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
          x, y = event.pos.map { |n| n / CELL_SIZE }
          cell = [x, y]
          if cell != @last_mouse_cell
            @last_mouse_cell = cell
            @record_grid[x][y] = Item.new lifetime, 'bonus'
            puts "#{lifetime} #{x},#{y} bonus"
          end
        end
      when Rubygame::MouseDownEvent
        x, y = event.pos.map { |n| n / CELL_SIZE }
        cell = [x, y]
        @record_grid[x][y] = Item.new lifetime, 'bonus'
        puts "#{lifetime} #{x},#{y} bonus"
      when Rubygame::QuitEvent
        @end = true
      end
    end
  end

  def accessible? x, y
    item = item(x, y)
    if item
      item.kind != 'block'
    else
      true
    end
  end

  def process_game_events(lifetime)
    loop do
      break if @game_events.nil?
      break if @game_events.empty?
      break if @game_events.first.time > lifetime
      event = @game_events.shift
      @grid[event.x][event.y] = Item.new event.time, event.kind
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
    if @player.direction
      next_x = @player.position.x + @player.next_move[0]
      next_y = @player.position.y + @player.next_move[1]      
      while lifetime >= @player.movement_lifetime + REPEAT_TIME && accessible?(next_x, next_y)
        @player.apply_direction
        @player.movement_lifetime += REPEAT_TIME
        next_x = @player.position.x + @player.next_move[0]
        next_y = @player.position.y + @player.next_move[1]
      end
    end
  end
  
  def catch_item
    if item(@player.x, @player.y)
       @grid[@player.x][@player.y] = nil
       @score += 10
    end
  end

  def update_record_grid(lifetime)
    each_record_item do |x, y, item|
      item.update lifetime
      unless item.alive?
        @record_grid[x][y] = nil
      end
    end
  end

  def update_record_grid(lifetime)
    each_record_item do |x, y, item|
      item.update lifetime
      unless item.alive?
        @record_grid[x][y] = nil
      end
    end
  end

  def update_record_grid(lifetime)
    each_record_item do |x, y, item|
      item.update lifetime
      unless item.alive?
        @record_grid[x][y] = nil
      end
    end
  end

  def apply_gravity lifetime
    while lifetime - @last_down_time > MILLISECONDS_PER_CELL
      @player.position.y += 1
      @last_down_time += MILLISECONDS_PER_CELL
    end
  end

  def update
    @screen.fill([0,0,0])
  
    lifetime = @clock.lifetime
    
    apply_gravity(lifetime)
    process_events(lifetime)
    process_game_events(lifetime)
    
    update_grid(lifetime)
    update_record_grid(lifetime)
    update_player(lifetime)

    catch_item
    
    draw
  end
  
  def draw
    each_item do |x, y, item|
      draw_item(x, y, item)
    end
    each_record_item do |x, y, item|
      draw_item(x, y, item)
    end

    each_record_item do |x, y, item|
      draw_item(x, y, item)
    end

    draw_player

    @font.render(score.to_s, true, [255, 255, 255]).blit(@screen, [100, 25])
    @screen.update
  end
  
  def draw_player
    surface = @media_bag['gfx/ninja.png'].to_display
    position = @player.position.dup
    position.x *= CELL_SIZE
    position.y *= CELL_SIZE
    surface.blit(@screen, position)
  end
  
  def draw_item(x, y, item)
    surface = @media_bag['gfx/bonus.png'].to_display
    surface.set_alpha item.life
    surface.blit(@screen, [x * CELL_SIZE, y * CELL_SIZE])
  end
  
  def item(x, y)
    @grid[x][y]
  end

  def record_item(x, y)
    @record_grid[x][y]
  end
  
  def record_item(x, y)
    @record_grid[x][y]
  end

  def end?
    @end
  end
end
