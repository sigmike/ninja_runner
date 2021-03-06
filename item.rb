# item est tout ce qui peut avoir un interaction avec Player

class Item
  attr_accessor :life, :kind, :x, :y
  
  def initialize birthtime, kind
    @birthtime = birthtime
    @life = 255
    @kind = kind
  end
  
  def update current_time
    @life = (ITEM_LIFETIME - (current_time - @birthtime)) * 255 / ITEM_LIFETIME
    @alive = (current_time - @birthtime) <= ITEM_LIFETIME
  end
  
  def alive?
    @alive
  end
end

