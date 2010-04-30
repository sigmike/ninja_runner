require 'rubygame'
require 'player'
require 'item'
require 'game_event'
require 'pp'

Rubygame.init
include Rubygame

ITEM_LIFETIME = 6000
REPEAT_TIME = 50
CELL_SIZE = 24
GRAVITY = 1 # cell down per second

MILLISECONDS_PER_CELL = 1000.0 / GRAVITY

Surface.autoload_dirs = [ 'gfx' ]

class Game
  attr_accessor :player,
    :screen,
    :scenario,
    :clock,
    :grid,
    :music_enabled,
    :score,
    :record_enabled
    
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
  
  # applique les évènements de l'utilisateur
  
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
            if @record_enabled
              @record_grid[x][y] = Item.new lifetime, 'bonus'
              puts "#{lifetime} #{x},#{y} bonus"
            end
          end
        end
      when Rubygame::MouseDownEvent
        x, y = event.pos.map { |n| n / CELL_SIZE }
        if !accessible?(x, y)
          @cell_mouse_click = [x, y, 0, 0]
          if @record_enabled
            @record_grid[x][y] = Item.new lifetime, 'bonus'
            puts "#{lifetime} #{x},#{y} bonus"
          end
        end
      when Rubygame::QuitEvent
        @end = true
      end
    end
  end

  def accessible? x, y
    item = item(x, y)
    if item
      item.kind != 'brick'
    else
      true
    end
  end
  
  # lit le scénario

  def process_game_events(lifetime)
    loop do
      break if @game_events.nil?
      break if @game_events.empty?
      break if @game_events.first.time > lifetime
      event = @game_events.shift
      @grid[event.x][event.y] = Item.new event.time, event.kind
    end
  end
  
  # vérifie la durée de vie des items
  
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
  
  def catch_item
    if item(@player.x, @player.y)
       @grid[@player.x][@player.y] = nil
       @score += 10
    end
  end
  
  # vérifie la durée de vie des items nouvellements enregistrés

  def update_record_grid(lifetime)
    each_record_item do |x, y, item|
      item.update lifetime
      unless item.alive?
        @record_grid[x][y] = nil
      end
    end
  end

  # fait tomber le joueur
  
  def apply_gravity lifetime
    while lifetime - @last_down_time > MILLISECONDS_PER_CELL

      old_player_direction = @player.direction
      
      @player.direction = :down
      @player.apply_direction if @player.can_move?
      @player.direction = old_player_direction
      
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
    
    draw_rope

    draw_player

    @font.render(score.to_s, true, [255, 255, 255]).blit(@screen, [100, 25])
    @screen.update
  end
  
  def draw_rope
    if @cell_mouse_click
      accroch_point = Rubygame::Rect.new(@cell_mouse_click)
      
      position = accroch_point.dup

      while position != @player.position
        break if accessible?(accroch_point.x, accroch_point.y)
      
        surface = Surface['rope.png']
        to_blit_position = position.dup
        to_blit_position.x *= CELL_SIZE
        to_blit_position.y *= CELL_SIZE
        surface.blit(@screen, to_blit_position)
        
        new_position = position.dup
        
        if position.x < @player.position.x
          new_position.x = accessible?(new_position.x + 1, new_position.y) ? new_position.x + 1 : new_position.x
        elsif position.x > @player.position.x
          new_position.x = accessible?(new_position.x - 1, new_position.y) ? new_position.x - 1 : new_position.x
        end
        
        if position.y < @player.position.y
          new_position.y = accessible?(new_position.x, new_position.y + 1) ? new_position.y + 1 : new_position.y
        elsif position.y > @player.position.y
          new_position.y = accessible?(new_position.x, new_position.y - 1) ? new_position.y - 1 : new_position.y
        end
        
        if position != new_position
          position = new_position
        else
          @cell_mouse_click = nil
          break
        end
      end
    end
  end
  
  def draw_player
    surface = Surface['ninja.png']
    position = @player.position.dup
    position.x *= CELL_SIZE
    position.y *= CELL_SIZE
    surface.blit(@screen, position)
  end
  
  def draw_item(x, y, item)
    surface = Surface["#{item.kind}.png"]
    surface.set_alpha item.life
    surface.blit(@screen, [x * CELL_SIZE, y * CELL_SIZE])
  end
  
  def item(x, y)
    raise "Invalid position: #{x},#{y}" if x < 0 or x >= @width or y < 0 or y >= @height
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
