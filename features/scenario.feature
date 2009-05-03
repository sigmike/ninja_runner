Feature: Scenario

Scenario: An item is present at good time
  Given the game is started
  Given a scenario
    """
    100 2,2
    200 3,2
    """
  When the clock goes to 99
  Then there's no item at 2,2
  When the clock goes to 100
  Then an item is at 2,2
  And there's no item at 3,3
  When the clock goes to 100 + ITEM_LIFETIME
  Then an item is at 2,2
  When the clock goes to 101 + ITEM_LIFETIME
  Then there's no item at 2,2
  When the clock goes to 201 + ITEM_LIFETIME
  Then there's no item at 3,2
