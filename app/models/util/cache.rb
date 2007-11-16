class Cache

  attr_accessor :max_size, :timeout
	
  def initialize(timeout = 60 * 60 * 24 , max_size = 64)
    self.max_size =  max_size
    self.timeout = timeout
    @map = Hash.new
  end
  
  def get(key)
    if @map.include? key
        @map[key][1] = Time.now
		    @map[key][0]
    else
      put(key, yield)
    end      
  end

  def size
    @map.size
  end
  
  def full?
    size >= max_size
  end

  def cleanup
    now = Time.now
    @map.delete_if {|key, value| now - value[1] > timeout }
    force_cleanup if full?
  end
  
private
 
	def put(key, value)
	  cleanup if full?
	  @map[key] = [value, Time.now]
    value
	end
	
  # delete the 10% least used objects
  def force_cleanup
    destroy = (max_size / 10) + 1
    times = @map.sort {|a, b| a[1][1] <=> b[1][1] }
    times = times[0, destroy]
    times.each {|time| @map.delete(time[0]) }
  end  
  
end