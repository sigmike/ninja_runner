require 'ninja_rope'
require 'spec/expectations'
require 'flexmock/rspec'

include FlexMock::ArgumentTypes
include FlexMock::MockContainer

Before do
  @game = Game.new
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
  Rubygame::Rect.new(*values.split.map(&:to_f))
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

When /^the clock goes to (\d+)$/ do |time|
  flexmock(@game.clock).should_receive(:lifetime).and_return(time.to_i).once
  @game.update
end

Then /^an item is at (\d+),(\d+)$/ do |x, y|
  @game.item(x.to_i, y.to_i).should_not be_nil
end

Then /^there's no item at (\d+),(\d+)$/ do |x, y|
  @game.item(x.to_i, y.to_i).should be_nil
end

Given /^escape was pressed$/ do
  event = Rubygame::KeyUpEvent.new(Rubygame::K_ESCAPE, [])
  flexmock(Rubygame).should_receive(:fetch_sdl_events).once.and_return([event])
end

When /^the game updates$/ do
  @game.update
end

Then /^the game should end$/ do
  @game.end?.should be_true
end
