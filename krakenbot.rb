require 'multi_json'
require 'kraken_client'

# WARNING: DANGEROUS
# Switches between simulation mode and real trading mode.
SIMULATION_MODE = true

###############################################
$simulation_ether_balance = 57.0 # Fake remote ether balance
$simulation_euro_balance = 69.0 # Fake remote euro balance
$simulation_ether_euro_ratio = 2.58021325643
$sim_step = 0

def next_sim_step
  if $sim_step >= SIM_DATA.count
    puts "SIM: Finished"
    total_euro = $euro_balance + $ether_balance * $ratio
    puts "~~~~ INFO: Current balance: #{$ether_balance} ETH + #{$euro_balance} EUR (#{total_euro} EUR) ~~~~"
    exit
  end
  $simulation_ether_euro_ratio = SIM_DATA[$sim_step][1]
  $sim_step = $sim_step + 1
end
###############################################

# TODO: Add dynamic trading fees.
TRADING_FEES_ETH_EUR = {
  0 => 0.0026,
  10000 => 0.0024,
  50000 => 0.0022,
  100000 => 0.0020,
  250000 => 0.0018,
  500000 => 0.0016,
  1000000 => 0.0014,
  5000000 => 0.0012,
  10000000 => 0.0010
}

$ether_balance = 0.0
$euro_balance = 200.0
$ratio = 0.0

def setup
  puts "Configuring client.."

  load 'config.rb'

  return KrakenClient.load
end

def trading_fees(quote_currency)
  quote_currency * 0.0026
end

def update_current_ratio(client)
  begin
    $ratio = client.public.ticker('XETHZEUR')["XETHZEUR"]["c"][0].to_f

    puts "(~)(~)(~) INFO: Current ratio: #{$ratio} EUR/ETH"
  rescue => e
    puts e.message
    return false
  end
  true
end

def update_balance(client)
  unless SIMULATION_MODE
    begin
      current_balance = client.private.balance
      $ether_balance = current_balance["XETH"].to_f
      $euro_balance = current_balance["ZEUR"].to_f
    rescue => e
      puts e.message
      return false
    end
  else
    $ether_balance = $simulation_ether_balance
    $euro_balance = $simulation_euro_balance
  end

  total_euro = $euro_balance + $ether_balance * $ratio
  puts "INFO: Current balance: #{$ether_balance} ETH + #{$euro_balance} EUR (#{total_euro} EUR)"
  true
end

def cancel_all_open_orders(client)
  if SIMULATION_MODE
  else
    begin
      orders = client.private.open_orders
    rescue => e
      puts e.message
    end
  end
  puts "INFO: Cancelled all open orders."
end

def place_buy_eth_order(client, price, volume)
  puts "(+)(+)(+) Buying #{volume} ETH for #{price} EUR/ETH"
  if SIMULATION_MODE
    if $ratio <= price
      price = $ratio # simulate market pricing
      total_cost = price * volume
      if total_cost <= $simulation_euro_balance
        $simulation_euro_balance = $simulation_euro_balance - total_cost
        total_reward = volume - trading_fees(volume)
        $simulation_ether_balance = $simulation_ether_balance + total_reward
        puts "SIM: Traded #{total_cost} EUR vs. #{total_reward} ETH"
      else
        puts "SIM: Cannot buy, not enough funds."
      end
    else
      puts "SIM: Cannot buy, price is above market limit."
    end
  else
    if volume.to_i == 0
      puts "Cannot buy zero eth.."
      return
    end

    begin
      client.private.add_order(
        {
          pair: 'ETHEUR',
          type: 'buy',
          ordertype: 'market',
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

def place_sell_eth_order(client, price, volume)
  puts "(-)(-)(-) Selling #{volume} ETH for #{price} EUR/ETH"

  if SIMULATION_MODE
    if $ratio >= price
      price = $ratio # simulate market pricing
      if volume <= $simulation_ether_balance
        $simulation_ether_balance = $simulation_ether_balance - volume
        total_reward = volume * price
        total_reward = total_reward - trading_fees(total_reward)
        $simulation_euro_balance = $simulation_euro_balance + total_reward
        puts "SIM: Traded #{volume} ETH vs. #{total_reward} EUR"
      else
        puts "SIM: Cannot sell, not enough ether."
      end
    else
      puts "SIM: Cannot sell, price is below market limit."
    end
  else
    if volume.to_i == 0
      puts "Cannot buy zero eth.."
      return
    end

    begin
      client.private.add_order(
        {
          pair: 'ETHEUR',
          type: 'sell',
          ordertype: 'market',
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

################################################################################

ratio_memory = []

strategy = :waiting
strategy_buy_threshold = 0.005
strategy_sell_threshold = 0.005
strategy_risk_distribution = 0.5

client = setup

while true do
  puts "---------------#{Time.now}--------------------"
  if update_balance(client)
    if update_current_ratio(client)

      ratio_memory << $ratio
      ratio_memory.shift unless ratio_memory.size <= 5
      ratio_average = ratio_memory.inject{ |sum, el| sum + el }.to_f / ratio_memory.size
      puts "AVERAGE RATIO: #{ratio_average}"

      tendency = $ratio - ratio_average
      puts "RATIO ABOVE AVERAGE: #{tendency}"

      strategy = :waiting

      if tendency < -strategy_sell_threshold
        strategy = :selling

        if $ether_balance == 0.0
          ratio_memory = [] << $ratio
          strategy = :waiting
        end
      end

      if tendency > strategy_buy_threshold
        strategy = :buying

        if $ether_balance > 0.0
          ratio_memory = [] << $ratio
        end
      end

      puts "RATIO MEMORY SIZE: #{ratio_memory.length}, STRATEGY: :#{strategy}"

      cancel_all_open_orders(client)
      case strategy
      when :buying
        if $euro_balance > 0
          if $euro_balance / $ratio * strategy_risk_distribution > 1
            place_buy_eth_order(client, $ratio, $euro_balance / $ratio * strategy_risk_distribution)
          end
        end
      when :selling
        if $ether_balance > 0
          if $ether_balance / $ratio * strategy_risk_distribution > 1
            place_sell_eth_order(client, $ratio, $ether_balance  * strategy_risk_distribution)
          end
        end
      when :waiting
      end

    end
  end

  sleep 15
end
