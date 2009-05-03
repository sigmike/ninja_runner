Feature: The player moves with arrow keys

Scenario Outline: The player moves right
  Given the game is started
  Given the player is at position <initial>
  When the <key> key is pressed
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

