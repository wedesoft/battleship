require 'fiber'
class WedesoftPlayer
  def name
    'Jan'
  end

  def new_game
    random = Random.new
    @generator = Fiber.new do
      # use Bayer dithering
      choices = (0 ... 100).collect { |n| [n % 10, n.div(10)] }.sort_by do |x,y|
        (0 ... 4).inject(0) do |order, bit|
          order | [0, 2, 3, 1][x[bit] | y[bit] << 1] << ((3 - bit) << 1)
        end
      end
      loop do
        x, y = choices.pop
        state, ships_remaining = Fiber.yield [x, y]
        if state[y][x] == :hit
          for dir in 0 ... 4
            x2, y2 = x, y
            while value(state, x2, y2) != :miss
              x2, y2 = *offset(x2, y2, dir)
              if value(state, x2, y2) == :unknown
                choices -= [[x2, y2]]
                state, ships_remaining = Fiber.yield [x2, y2]
              end
            end
          end
        end
      end
    end
    [
      [rand(4) + 1, 1, 5, :across],
      [rand(5) + 1, 3, 4, :across],
      [rand(6) + 1, 5, 3, :across],
      [8, 7, 3, :down  ],
      [1, 9, 2, :across]
    ]
  end

  def value(state, x, y)
    if (0..9).member?(x) and (0..9).member?(y)
      state[y][x]
    else
      :miss
    end
  end

  def offset(x, y, dir)
    case dir
    when 0
      [x + 1, y]
    when 1
      [x, y + 1]
    when 2
      [x - 1, y]
    when 3
      [x, y - 1]
    end
  end

  def take_turn(state, ships_remaining)
    @generator.resume state, ships_remaining
  end
end

