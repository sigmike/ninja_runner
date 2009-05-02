Feature: A rect knows whether it's inside another one

Scenario: Rect is inside
  Given the rect is at 0 0 10 10
  And the other rect is at -10 -10 20 20
  Then the rect is inside the other rect

Scenario: Rect is outside
  Given the rect is at 30 30 10 10
  And the other rect is at -10 -10 20 20
  Then the rect is not inside the other rect
