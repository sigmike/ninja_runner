require 'rubygame'
require 'player'
require 'item'
require 'game_event'
require 'rope'
require 'rubygame/mediabag'
require 'pp'

Rubygame.init
include Rubygame

ITEM_LIFETIME = 3000
REPEAT_TIME = 100
CELL_SIZE = 24
GRAVITY = 5 # cell down per second

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
    :record_enabled,
    :rope
    
  attr_reader :width, :height
  
  def start
    @player = Player.new(self)
    @rope = Rope.new(self)
    @clock = Rubygame::Clock.new
    Rubygame::TTF.setup
    @font = Rubygame::TTF.new 'fonts/arial.ttf', 32
    @width = 40
    @height = 24
    @score = 0
    @last_down_time = 0.0
    @grid = Array.new(@width) { Array.new(@height) }
    @record_grid = Array.new(@width) { Array.new(@height) }
    @screen = Rubygame::Screen.new([@width * CELL_SIZE, @height * CELL_SIZE])
    @catched_item = []
    
    if @music_enabled
      @music = Rubygame::Music.load "music/2 - Please.mp3"
      @music.play
    end
    
    @media_bag = Rubygame::MediaBag.new
    @media_bag.load_image "gfx/ninja_left.png"
    @media_bag.load_image "gfx/ninja_right.png"
    @media_bag.load_image "gfx/bonus.png"
    @media_bag.load_image "gfx/brick.png"
    @media_bag.load_image "gfx/rope.png"
    @media_bag.load_image "gfx/background.png" #960 x 476
    
    @surface_brick = @media_bag['gfx/brick.png'].to_display
    @surface_bonus = @media_bag['gfx/bonus.png'].to_display
    @surface_background = @media_bag["gfx/background.png"].to_display
    @surface_ninja_left = @media_bag["gfx/ninja_left.png"].to_display_alpha
    @surface_ninja_right = @media_bag["gfx/ninja_right.png"].to_display_alpha
    
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
        case event.button
          when Rubygame::MOUSE_LEFT:
            if !accessible?(x, y)
              # accroche la rope
              @cell_mouse_click = [x, y, 0, 0]
              @rope.accroch(@cell_mouse_click)
              if @record_enabled
                @record_grid[x][y] = Item.new lifetime, 'bonus'
                puts "#{lifetime} #{x},#{y} bonus"
              end
            end
          when Rubygame::MOUSE_RIGHT
            # décroche la rope
            @rope.deccroch
        end
      when Rubygame::QuitEvent
        @end = true
      end
    end
  end

  # indique si une case peut être parcourue par le joueur
  
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
  
  # mets à jour la vie des items catchés
  
  def update_catched_items(lifetime)
    @catched_item.each do |item|
      item.update(lifetime)
      unless item.alive?
        @catched_item.delete(item)
      end
    end
  end
  
  # fait bouger le Player
  
  def update_player(lifetime)
    @player.move(lifetime)
  end
  
  def catch_item(lifetime)
    if item(@player.x, @player.y)
       item = @grid[@player.x][@player.y]
       if item.kind == 'bonus'
         i = Item.new(lifetime, item.kind)
         i.x = @player.x
         i.y = @player.y
         @catched_item << i
         @score += 10
       end 
       @grid[@player.x][@player.y] = nil
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
  
  def accroch_point
    if @cell_mouse_click
      Rubygame::Rect.new(@cell_mouse_click)
    else
      nil
    end
  end
  
  # met à jour le chemin de la rope
  
  def update_rope_path
    @rope.update
  end
  
  # fait tomber le joueur
  
  def apply_gravity_with_rope_contraint lifetime
    if @rope.max_down?
      @last_down_time = lifetime
    else
      
      while lifetime - @last_down_time > MILLISECONDS_PER_CELL
        old_player_direction = @player.direction
        
        if @rope.active? && @rope.accroch_point_at_top?
          @player.direction = @rope.accroch_point_at_left? ? :left : :right
          @player.apply_direction(false) if @player.can_move?
        end
        
        if @rope.max_down?
          @player.direction = old_player_direction
          @last_down_time = lifetime
          break
        end
        
        @player.direction = :down
        @player.apply_direction(false) if @player.can_move?

        @player.direction = old_player_direction

        @last_down_time += MILLISECONDS_PER_CELL
      end
    end
  end

  def update
    @screen.fill([0,0,0])
  
    lifetime = @clock.lifetime

    process_events(lifetime)
    process_game_events(lifetime)
    
    update_rope_path
    apply_gravity_with_rope_contraint(lifetime)
    update_rope_path
        
    update_record_grid(lifetime)
    update_player(lifetime)
    update_grid(lifetime)

    update_catched_items(lifetime)
    
    draw(lifetime)
  end
  
  def draw lifetime
    draw_background
  
    score_offset_x = rand(6) - 3
    score_offset_y = rand(6) - 3
     @font.render('time: ' + lifetime.to_s, false, [79, 48, 11]).blit(@screen, [100, 25])
    @font.render('time: ' + lifetime.to_s, false, [37, 34, 29]).blit(@screen, [100 + score_offset_x, 25 + score_offset_y])
    
     @font.render(score.to_s + ' points', true, [238, 154, 44]).blit(@screen, [770, 25])
    
    @font.render(score.to_s + ' points', true, [241, 225, 53]).blit(@screen, [770 + score_offset_x, 25 + score_offset_y])
    
    
    each_item do |x, y, item|
      draw_item(x, y, item)
    end
    
    each_record_item do |x, y, item|
      draw_item(x, y, item)
    end

    @rope.path.each do |position|
      draw_rope(position)
    end
    
    @catched_item.each do |item|
      draw_catched_item item
    end

    draw_player

    @screen.update
  end
  
  def draw_catched_item(item)
    surface = @media_bag["gfx/bg_navy_score10.png"].to_display
    surface.alpha= item.life
    surface.blit(@screen, [item.x * CELL_SIZE + rand(5), (item.y - ((256 - item.life) / CELL_SIZE )) * CELL_SIZE])
  end
  
  def draw_rope(position)
    surface = @media_bag["gfx/rope.png"].to_display_alpha
    position = position.dup
    position.x *= CELL_SIZE
    position.y *= CELL_SIZE
    surface.blit(@screen, position)
  end
  
  def draw_background
    surface = @surface_background
    surface.blit(@screen, [0, 0])
  end
  
  def draw_player
    surface = @player.direction == :left ? @surface_ninja_left : @surface_ninja_right
    position = @player.position.dup
    position.x *= CELL_SIZE
    position.y *= CELL_SIZE
    surface.blit(@screen, position)
  end
  
  def draw_item(x, y, item)
    surface = item.kind == 'brick' ? @surface_brick : @surface_bonus
    surface.alpha= item.life
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
