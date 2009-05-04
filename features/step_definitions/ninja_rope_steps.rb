require 'ninja_rope'
require 'spec/expectations'
require 'flexmock/rspec'

include FlexMock::ArgumentTypes
include FlexMock::MockContainer

def Rubygame.fetch_sdl_events
  @events ||= []
  result = @events.dup
  @events.clear
  result
end

def Rubygame.push_event(event)
  @events ||= []
  @events << event
end

Before do
  @game = Game.new
  @mouse_buttons = []
  flexmock(Rubygame::Music).should_receive(:load).and_return do
    flexmock(:play => nil)
  end
end

When /^the game starts$/ do
  @game.start
end

Given /^the game is started$/ do
  @game.start
end

Then /^the player is inside the screen$/ do
  @game.player.position.inside?(@game.screen).should be_true
end

def new_rect(values)
  Rubygame::Rect.new(*values.split.map { |n| n.to_f })
end

Given /^the rect is at (.+)$/ do |values|
  @rect = new_rect(values)
end

Given /^the other rect is at (.+)$/ do |values|
  @other_rect = new_rect(values)
end

Then /^the rect is inside the other rect$/ do
  @rect.inside?(@other_rect).should be_true
end

Then /^the rect is not inside the other rect$/ do
  @rect.inside?(@other_rect).should be_false
end

Given /^a scenario$/ do |scenario|
  @game.scenario = scenario
end

def game_update_at(time)
  flexmock(@game.clock).should_receive(:lifetime).and_return(time.to_i).once
  @game.update
end

When /^the clock goes to (.+)$/ do |time|
  time_value = eval(time)
  game_update_at(time_value)
end

Given /^an item is at (\d+),(\d+)$/  do |x, y|
  item = Item.new @game.clock.lifetime
  @game.grid[x.to_i][y.to_i] = item
end

Then /^an item should be at (\d+),(\d+)$/ do |x, y|
  @game.item(x.to_i, y.to_i).should_not be_nil
end

Then /^there should be no item at (\d+),(\d+)$/ do |x, y|
  @game.item(x.to_i, y.to_i).should be_nil
end

Given /^escape was pressed$/ do
  Rubygame.push_event Rubygame::KeyUpEvent.new(Rubygame::K_ESCAPE, [])
end

When /^the game updates$/ do
  @game.update
end

Then /^the game should end$/ do
  @game.end?.should be_true
end

Then /^the game window should be created$/ do
  @game.screen.class.should == Rubygame::Screen
end

Given /^the events are recorded$/ do
  @recorded_events = []
  flexmock(@game).should_receive(:puts).and_return do |event|
    @recorded_events << event
  end
end

When /^the mouse button is pressed at cell (\d+),(\d+) and time (\d+)$/ do |x, y, time|
  mouse_x = x.to_i * 24
  mouse_y = y.to_i * 24
  @mouse_buttons << Rubygame::MOUSE_LEFT
  Rubygame.push_event Rubygame::MouseDownEvent.new([mouse_x.to_i, mouse_y.to_i], Rubygame::MOUSE_LEFT)
  game_update_at(time)
end

When /^the mouse is moved to cell (\d+),(\d+) at time (\d+)$/ do |x, y, time|
  mouse_x = x.to_i * 24
  mouse_y = y.to_i * 24
  Rubygame.push_event Rubygame::MouseMotionEvent.new([mouse_x.to_i, mouse_y.to_i], [0, 0], @mouse_buttons)
  game_update_at(time)
end

When /^the mouse is moved to another position in cell (\d+),(\d+) at time (\d+)$/ do |x, y, time|
  mouse_x = x.to_i * 24 + 3
  mouse_y = y.to_i * 24 + 5
  Rubygame.push_event Rubygame::MouseMotionEvent.new([mouse_x.to_i, mouse_y.to_i], [0, 0], @mouse_buttons)
  game_update_at(time)
end

When /^the mouse button is released at cell (\d+),(\d+) and time (\d+)$/ do |x, y, time|
  mouse_x = x.to_i * 24
  mouse_y = y.to_i * 24
  @mouse_buttons.delete Rubygame::MOUSE_LEFT
  Rubygame.push_event Rubygame::MouseUpEvent.new([mouse_x.to_i, mouse_y.to_i], Rubygame::MOUSE_LEFT)
  game_update_at(time)
end

Then /^the event (\d+) is "(.+)"$/ do |index, expected|
  @recorded_events[index.to_i].should == expected
end

Then /^there's no event (\d+)$/ do |index|
  @recorded_events[index.to_i].should be_nil
end

Given /^the player is at position (\d+),(\d+)$/ do |x, y|
  @game.player.position.x = x.to_i
  @game.player.position.y = y.to_i
end

When /^the (.+) key is (pressed down|released)$/ do |key, action|
  mapping = {
    "right" => Rubygame::K_RIGHT,
    "left" => Rubygame::K_LEFT,
    "up" => Rubygame::K_UP,
    "down" => Rubygame::K_DOWN,
  }
  symbol = mapping[key]
  raise "Invalid key: #{key.inspect}" unless symbol
  
  case action
  when "pressed down"
    klass = Rubygame::KeyDownEvent
  when "released"
    klass = Rubygame::KeyUpEvent
  end
   
  Rubygame.push_event klass.new(symbol, [])
  @game.update
end

Then /^player position should be (\d+),(\d+)$/ do |x,y|
  [@game.player.position.x, @game.player.position.y].should == [x.to_i, y.to_i]
end

Then /^the grid size should be 40,24$/ do
  @game.grid_size.should == [40, 24]
end

Given /^the music is (enabled|disabled)$/ do |status|
  @game.music_enabled = (status == "enabled" ? true : false)
end

Then /^the music should be playing$/ do
  @game.music_playing?.should be_true
end

Then /^the music should not be playing$/ do
  @game.music_playing?.should_not be_true
end

Then /^the score should be (\d+)$/ do |score|
   @game.score.should == score.to_i
end

Then /^a record item is at (\d+),(\d+)$/ do |x, y|
  @game.record_item(x.to_i, y.to_i).should_not be_nil
end

Then /^the player position should be below (\d+),(\d+)$/ do |x,y|
  @game.player.position.y.should > y.to_i
end
