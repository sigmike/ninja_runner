# GameEvent contient un évenement temporel dans le scénario

class GameEvent
  attr_accessor :time, :x, :y, :kind

  def initialize(time, x, y, kind)
    @time = time
    @x = x
    @y = y
    @kind = kind
  end
end

