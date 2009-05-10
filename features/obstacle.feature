Feature: Some blocks stop the player

Scenario: Game can detect a block
  Given the game is started
  Given a block at position 6,5
  Then game can detect a block at 6,5

Scenario: There's a block at right and the player can't going to 
  Given the game is started
  Given the player is at position 5,5
  Given a block at position 6,5
  When the right key is pressed down
  Then player position should be 5,5

