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

require './tradebots/tradebot'

class KrakenTradebot < Tradebot
  def initialize
    @simulation_base_currency_balance = 200.0
    @simulation_quote_currency_balance = 0.0
    self
  end

  def with_kraken_client(kraken_client)
    @kraken_client = kraken_client
    self
  end

  def for_currency_pair(curreny_pair)
    @curreny_pair = curreny_pair
    self
  end

  def in_simulation_mode
    @simulation_mode = true
    self
  end

  def update_ticker_values
    update_ratio &&
      update_balance
  end

  def buy(price, volume)
    puts "Buying #{volume} #{@quote_currency} for #{price} #{@base_currency}/#{@quote_currency}"
    if @simulation_mode
      if @ratio <= price
        price = @ratio # simulate market pricing
        total_cost = price * volume
        if total_cost <= @simulation_base_currency_balance
          @simulation_base_currency_balance = @simulation_base_currency_balance - total_cost
          total_reward = volume - trading_fees(volume)
          @simulation_quote_currency_balance = @simulation_quote_currency_balance + total_reward
          puts "SIM: Traded #{total_cost} #{@base_currency} vs. #{total_reward} #{@quote_currency}"
        else
          puts "SIM: Cannot buy, not enough funds."
        end
      else
        puts "SIM: Cannot buy, price is above market limit."
      end
    else
      if volume.to_i == 0
        puts "Cannot buy zero #{@base_currency}.."
        return
      end

      begin
        @kraken_client.private.add_order(
          {
            pair: "#{@quote_currency}#{@base_currency}",
            type: 'buy',
            ordertype: 'limit',
            price: price,
            volume: volume.to_i + 1,
            trading_agreement: 'agree'
          }
        )
      rescue => e
        puts e.message
      end
    end
  end

  def sell(price, volume)
    puts "Selling #{volume} #{@quote_currency} for #{price} #{@base_currency}/#{@quote_currency}"

    if @simulation_mode
      if @ratio >= price
        price = @ratio # simulate market pricing
        if volume <= @simulation_quote_currency_balance
          @simulation_quote_currency_balance = @simulation_quote_currency_balance - volume
          total_reward = volume * price
          total_reward = total_reward - trading_fees(total_reward)
          @simulation_base_currency_balance = @simulation_base_currency_balance + total_reward
          puts "SIM: Traded #{volume} #{@quote_currency} vs. #{total_reward} #{@base_currency}"
        else
          puts "SIM: Cannot sell, not enough ether."
        end
      else
        puts "SIM: Cannot sell, price is below market limit."
      end
    else
      if volume.to_i == 0
        puts "Cannot buy zero #{@quote_currency}.."
        return
      end

      begin
        @kraken_client.private.add_order(
          {
            pair: "#{@quote_currency}#{@base_currency}",
            type: 'sell',
            ordertype: 'limit',
            price: price,
            volume: volume.to_i,
            trading_agreement: 'agree'
          }
        )
      rescue => e
        puts e.message
      end
    end
  end

  private

  def update_balance
    unless @simulation_mode
      begin
        current_balance = @kraken_client.private.balance
        @base_currency_balance = current_balance[@base_currency].to_f
        @quote_currency_balance = current_balance[@quote_currency].to_f
      rescue => e
        puts e.message
        return false
      end
    else
      @base_currency_balance = @simulation_base_currency_balance
      @quote_currency_balance = @simulation_quote_currency_balance
    end

    total_value = @base_currency_balance + @quote_currency_balance * @ratio
    puts "INFO: Current balance: #{@quote_currency_balance} #{@quote_currency} + #{@base_currency_balance} #{@base_currency} (#{total_value} #{@base_currency})"
    true
  end

  def update_ratio
    begin
      currency_string = "#{@quote_currency}#{@base_currency}"
      response = @kraken_client.public.ticker(currency_string)[currency_string]

      @low = response["l"].min.to_f
      @high = response["h"].max.to_f
      @ratio = response["c"][0].to_f
    rescue => e
      puts "UPDATE RATIO: #{e.message}"
      return false
    end

    puts "INFO: Current ratio: #{@ratio} #{@base_currency}/#{@quote_currency} l: #{@low} h: #{@high}"
    true
  end

  def trading_fees(quote_currency)
    quote_currency * 0.0026
  end

end
