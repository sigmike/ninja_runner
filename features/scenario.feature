Feature: Scenario

Scenario: An item is present at good time
  Given the game is started
  Given a scenario
    """
    100 2,2 bonus
    200 3,2 brick
    """
  When the clock goes to 99
  Then there should be no item at 2,2
  When the clock goes to 100
  Then an item should be at 2,2
  Then an item should be bonus at 2,2
  And there should be no item at 3,3
  When the clock goes to 200
  Then an item should be brick at 3,2
  When the clock goes to 100 + ITEM_LIFETIME
  Then an item should be at 2,2
  When the clock goes to 101 + ITEM_LIFETIME
  Then there should be no item at 2,2
  When the clock goes to 201 + ITEM_LIFETIME
  Then there should be no item at 3,2

