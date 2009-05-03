Feature: The scenario can be recorded

Scenario: Record multiple events while draging with the mouse
  Given the events are recorded
  And the game is started
  When the mouse button is pressed at cell 1,1 and time 100
  And the mouse is moved to cell 2,1 at time 160
  And the mouse is moved to another position in cell 2,1 at time 165
  And the mouse is moved to cell 2,1 at time 170
  And the mouse is moved to cell 3,1 at time 180
  When the mouse button is released at cell 3,1 and time 200
  Then the event 0 is "100 1,1"
  And the event 1 is "160 2,1"
  And the event 2 is "180 3,1"
  And there's no event 3
  
Scenario: No record if mouse button is not pressed
  Given the events are recorded
  And the game is started
  When the mouse is moved to cell 2,1 at time 160
  Then there's no event 0
