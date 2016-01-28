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

require 'multi_json'
require 'kraken_client'

require './kraken_tradebot'
require './conservative_strategy'
require './config.rb'

kraken_tradebot = KrakenTradebot.new
  .with_kraken_client(KrakenClient.load)
  .with_base_currency('ZEUR')
  .with_quote_currency('XETH')
  .with_strategy(ConservativeStrategy)
  #.in_simulation_mode

while true do
  puts "---------------#{Time.now}--------------------"
  kraken_tradebot.poll
  sleep 5
end
