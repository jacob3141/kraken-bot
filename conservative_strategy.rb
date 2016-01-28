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

    @buy_risk_distribution = 0.5
    @sell_risk_distribution = 0.8
    @pushing_up = false
  end

  def poll
    range = @tradebot.high - @tradebot.low
    buy_under = (@tradebot.low + range * 0.3)
    sell_over = (@tradebot.high - 0.02)

    puts "Buying under #{buy_under}, selling over #{sell_over}, pushed up: #{@pushing_up}"

    if @tradebot.ratio < buy_under
      @pushing_up = false
      if @tradebot.base_currency_balance > 0
        amount = @tradebot.base_currency_balance / @tradebot.ratio * @buy_risk_distribution
        if amount > 1
         @tradebot.buy(@tradebot.ratio, amount)
        end
      end
    else

      if @tradebot.ratio > sell_over && !@pushing_up
        @pushing_up = true
      end

      if @tradebot.ratio < sell_over && @pushing_up
        if @tradebot.quote_currency_balance > 0
          amount = @tradebot.quote_currency_balance * @sell_risk_distribution
          if amount > 1
           @tradebot.sell(@tradebot.ratio, amount)
          end
        end
      end

    end

  end
end
