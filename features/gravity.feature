Feature: The player is affected by the gravity

  Background:
    Given the game is started

  Scenario: There's nothing under the player's feet and the player falls down
    Given the player is at position 5,5
    When the clock goes to 1000
    Then the player position should be below 5,5
  