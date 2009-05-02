Feature: Scenario

Scenario: An item is present at good time
  Given the game is started
  Given a scenario
    """
    100 2,2
    """
  When the clock goes to 99
  Then there's no item at 2,2
  When the clock goes to 100
  Then an item is at 2,2