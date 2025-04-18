# Description: This module provides a method to split a total amount into parts based on given percentages.
# The method takes a total amount and an array of percentages, and returns an array of amounts corresponding to each percentage.
# 
# @param total [Numeric] The total amount to be split.
# @param percentages [Array<Numeric>] An array of percentages (as decimals) that represent the proportion of the total for each part.
# @return [Array<Numeric>] An array of amounts corresponding to each percentage.

# Percentages are expected to be in the range of 0 to 100.
module SplitByPercentage
  def split_by_percentage(total, percentages)
    raise ArgumentError.new("percentages must sum to 100. Given: (#{percentages.join(',')})") if percentages.sum != 100

    # Step 1: Calculate raw float allocations
    raw = percentages.map { |p| total * p / 100.0 }

    # Step 2: Floor the values to get initial allocation
    base = raw.map(&:floor)

    # Step 3: Calculate how many units are left to distribute
    remainder = total - base.sum

    # Step 4: Distribute remainder to the ones with largest decimals
    decimal_parts = raw.map.with_index { |val, i| [val - base[i], i] }
    decimal_parts.sort_by! { |frac, _i| -frac } # descending

    remainder.times do |i|
      base[decimal_parts[i][1]] += 1
    end

    base
  end
end
