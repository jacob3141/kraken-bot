# Copyright (c) 2016 Jacob Dawid
#
# This file is part of kraken-bot.
#
# kraken-bot is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

require './strategies/strategy'

# This strategy works with two limit barriers that can either be dynamic or
# fixed. The strategy is buying below the lower barrier and either selling
# as soon as the ratio went up higher than the higher barrier, or waiting after
# the ratio went up and leaves the high back again (ie. it is not selling as
# long as there is a chance the ratio is "pushing" high).
class ConservativeStrategy < Stragegy
  def initialize
    @buying_ratio = 0.5
    @selling_ratio = 0.8

    @buying_under = 0.3
    @selling_over = 0.95

    @range = nil
    @only_sell_after_push = false

    @pushing_up = false
  end

  def with_buying_ratio(buying_ratio)
    @buying_ratio = buying_ratio
    self
  end

  def with_selling_ratio(selling_ratio)
    @selling_ratio = selling_ratio
    self
  end

  def buying_under(buying_under)
    @buying_under = buying_under
    self
  end

  def selling_over(selling_over)
    @selling_over = selling_over
    self
  end

  def at_custom_range(low, high)
    @range = [low, high]
    self
  end

  def at_auto_range
    @range = nil
    self
  end

  def and_only_sell_after_pushing_high
    @only_sell_after_push = true
    self
  end

  def and_always_sell_on_high
    @only_sell_after_push = false
    self
  end

  def poll
    limits = if @range.nil?
      amplitude = @tradebot.high - @tradebot.low
      [
        @tradebot.low + amplitude * @buying_under,
        @tradebot.low + amplitude * @selling_over
      ]
    else
      amplitude = @range.second - @range.first
      [
        @range.first + amplitude * @buying_under,
        @range.first + amplitude * @selling_over
      ]
    end

    puts "#{@tradebot.low}-#{@tradebot.high}: Buying under #{limits[0]}, selling over #{limits[1]}, pushed up: #{@pushing_up}"

    if @tradebot.ratio < limits[0]
      @pushing_up = false
      if @tradebot.base_currency_balance > 0
        amount = @tradebot.base_currency_balance / @tradebot.ratio * @buying_ratio
        if amount >= 1
         @tradebot.buy(@tradebot.ratio, amount)
        end
      end
    else

      if @only_sell_after_push # sell after ratio has reached over upper limit
        if @tradebot.ratio > limits[1] && !@pushing_up
          @pushing_up = true
        end

        if @tradebot.ratio < limits[1] && @pushing_up
          if @tradebot.quote_currency_balance > 0
            amount = @tradebot.quote_currency_balance * @selling_ratio
            if amount >= 1
             @tradebot.sell(@tradebot.ratio, amount)
            end
          end
        end
      else # always sell
        if @tradebot.ratio > limits[1]
          if @tradebot.quote_currency_balance > 0
            amount = @tradebot.quote_currency_balance * @selling_ratio
            if amount >= 1
             @tradebot.sell(@tradebot.ratio, amount)
            end
          end
        end
      end

    end

  end
end
