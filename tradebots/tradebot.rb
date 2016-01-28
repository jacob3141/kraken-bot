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

class Tradebot
  def initialize
    self
  end

  def with_base_currency(base_currency)
    @base_currency = base_currency
    self
  end

  def with_quote_currency(quote_currency)
    @quote_currency = quote_currency
    self
  end

  def with_strategy(strategy)
    @strategy = strategy.hook_up(self)
    self
  end

  def update_ticker_values
    true
  end

  def base_currency_balance
    @base_currency_balance
  end

  def quote_currency_balance
    @quote_currency_balance
  end

  def ratio
    @ratio
  end

  def low
    @low
  end

  def high
    @high
  end

  def buy(price, volume)
    raise "Must be implemented on subclass."
  end

  def sell(price, volume)
    raise "Must be implemented on subclass."
  end

  def poll
    raise "No strategy set for tradebot." if @strategy.nil?
    @strategy.poll if update_ticker_values
  end
end
