Feature: The player is affected by the gravity

  Scenario: There's nothing under the player's feet and the player falls down
    Given the game is started
    Given the player is at position 5,5
    When the clock goes to 1001
    Then the player position should be below 5,5

  Scenario Outline: There's nothing under the player's feet and the player falls down (complex)
    Given the game is started
    Given the player is at position <initial>
    When the clock goes to 1001
    Then the player position should be below  <destination>
  
  Examples:
    |  5,23   | 5,0         |

