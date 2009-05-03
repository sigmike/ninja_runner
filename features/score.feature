Feature: increase score by catching bonus

Scenario: player catch bonus
  Given the game is started
  Given the player is at position 5,5
  Given an item is at 5,5
  When the game updates
  Then there should be no item at 5,5
  Then the score should be 10
  
  Given the player is at position 5,6
  Given an item is at 5,6
  When the game updates
  Then there should be no item at 5,6
  Then the score should be 20

