Feature: Music

Scenario: The music is started when music is enabled
  Given the music is enabled
  When the game is started
  Then the music should be playing

Scenario: The music is started when music is disabled
  Given the music is disabled
  When the game is started
  Then the music should not be playing

  