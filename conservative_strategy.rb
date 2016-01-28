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

require './strategy'

class ConservativeStrategy < Stragegy
  def initialize
    @ratio_memory = []

    @strategy = :waiting
    @buy_threshold = 0.01
    @sell_threshold = 0.01
    @buy_risk_distribution = 0.4
    @sell_risk_distribution = 0.6
    @average_size = 3
  end

  def poll
    @ratio_memory << @tradebot.ratio
    @ratio_memory.shift unless @ratio_memory.size <= @average_size
    ratio_average = @ratio_memory.inject{ |sum, el| sum + el }.to_f / @ratio_memory.size
    puts "AVERAGE RATIO: #{ratio_average}"

    tendency = @tradebot.ratio - ratio_average
    puts "RATIO ABOVE AVERAGE: #{tendency}"

    @strategy = :waiting

    if tendency < -@sell_threshold
      @strategy = :selling

      if @tradebot.quote_currency_balance == 0.0
        @ratio_memory = [] << @tradebot.ratio
        @strategy = :waiting
      end
    end

    if tendency > @buy_threshold
      @strategy = :buying

      if @tradebot.quote_currency_balance > 0.0
        @ratio_memory = [] << @tradebot.ratio
      end
    end

    puts "RATIO MEMORY SIZE: #{@ratio_memory.length}, STRATEGY: :#{@strategy}"

    case @strategy
    when :buying
      if @tradebot.base_currency_balance > 0
        amount = @tradebot.base_currency_balance / @tradebot.ratio * @buy_risk_distribution
        if amount > 1
          @tradebot.buy(@ratio, amount)
        end
      end
    when :selling
      if @tradebot.quote_currency_balance > 0
        amount = @tradebot.quote_currency_balance * @sell_risk_distribution
        if amount > 1
          @tradebot.sell(@ratio, amount)
        end
      end
    when :waiting
    end
  end
end
