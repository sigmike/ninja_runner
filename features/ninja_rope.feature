Feature: Ninja rope game

Scenario: The player starts in the screen
  When the game starts
  Then the player is inside the screen

Scenario: Escape is pressed and the game ends
  Given the game is started
  Given escape was pressed
  When the game updates
  Then the game should end

Scenario: The game window is created
  When the game starts
  Then the game window should be created
  