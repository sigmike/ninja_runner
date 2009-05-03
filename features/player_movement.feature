Feature: The player moves with arrow keys

Scenario Outline: The player moves right
  Given the game is started
  Given the player is at position <initial>
  When the <key> key is pressed down
  Then player position should be <destination>
  
  Examples:
    | initial | key   | destination |
    |  3,1    | right | 4,1         |
    |  39,1   | right | 0,1         |
    |  39,1   | left  | 38,1        |
    |  0,1    | left  | 39,1        |
    |  0,1    | up    | 0,0         |
    |  0,0    | up    | 0,23        |
    |  0,0    | down  | 0,1         |
    |  5,23   | down  | 5,0         |

Scenario Outline: The player keeps moving while the key is pressed
  Given the game is started
  Given the player is at position <initial>
  When the clock goes to 0
  And the <key> key is pressed down
  And the clock goes to <time>
  Then player position should be <destination>

  Examples:
    | initial | key   | time | destination |
    |  3,1    | right |  REPEAT_TIME - 1 | 4,1         |
    |  3,1    | right |  REPEAT_TIME     | 5,1         |
    |  3,1    | right |  REPEAT_TIME + 1 | 5,1         |

Scenario: The player presses two keys and releases one
  Given the game is started
  Given the player is at position 1,1
  When the clock goes to 100
  And the right key is pressed down
  And the left key is pressed down
  And the right key is released
  And the clock goes to 100 + REPEAT_TIME
  Then player position should be 0,1
