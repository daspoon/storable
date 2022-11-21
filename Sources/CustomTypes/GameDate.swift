/*

*/

typealias GameDate = Int

typealias GameDateRange = Int


// --------------------------------------------------------------------------------

func makeGameDate(month m: Int, day d: Int) -> GameDate?
  {
    guard (1 ... 12).contains(m), (1 ... 31).contains(d) else { return nil }
    return (m >= 4 ? m : m + 12) * 32 + d
  }


func monthOfGameDate(_ date: GameDate) -> Int
  { let m = date / 32; return m <= 12 ? m : m - 12 }

func dayOfGameDate(_ date: GameDate) -> Int
  { date % 32 }


func parseGameDate(_ string: String) -> GameDate?
  {
    let substrings = string.components(separatedBy: "/")
    let numbers = substrings.compactMap {Int($0)}
    guard substrings.count == 2, numbers.count == 2, (1 ... 12).contains(numbers[0]), (1 ... 31).contains(numbers[1]) else { return nil }
    return makeGameDate(month: numbers[0], day: numbers[1])
  }

func printGameDate(_ date: GameDate) -> String
  { "\(monthOfGameDate(date))/\(dayOfGameDate(date))" }


let minGameDate = makeGameDate(month:  4, day:  9)!
let maxGameDate = makeGameDate(month: 15, day: 19)!


// --------------------------------------------------------------------------------

func makeGameDateRange(lb: GameDate?, ub: GameDate?) -> GameDateRange?
  {
    guard lb != nil || ub != nil else { return nil }
    return (lb ?? 0) | ((ub ?? 0) << 32)
  }


func lowerBoundOfGameDateRange(_ range: GameDateRange) -> GameDate?
  { let lb = range & 0xffffffff; return lb > 0 ? lb : nil }

func upperBoundOfGameDateRange(_ range: GameDateRange) -> GameDate?
  { let ub = (range >> 32) & 0xffffffff; return ub > 0 ? ub : nil }


func parseGameDateRange(_ string: String) -> GameDateRange?
  {
    // Require two elements separated by '-'.
    let substrings = string.components(separatedBy: "-")
    guard (1 ... 2).contains(substrings.count) else { return nil }
    // Each element must either be empty of a valid date.
    let dates = substrings.map { parseGameDate($0) }
    guard zip(substrings, dates).allSatisfy({$0 == "" || $1 != nil}) else { return nil }

    return makeGameDateRange(lb: dates.first!, ub: dates.last!)
  }

func printGameDateRange(_ range: GameDateRange) -> String
  {
    switch (lowerBoundOfGameDateRange(range), upperBoundOfGameDateRange(range)) {
      case (.some(let lb), .some(let ub)) where lb == ub :
        return printGameDate(lb)
      case (.some(let lb), .some(let ub))  :
        return printGameDate(lb) + "-" + printGameDate(ub)
      case (.some(let lb), .none) :
        return printGameDate(lb) + "-"
      case (.none, .some(let ub)) :
        return "-" + printGameDate(ub)
      case (.none, .none) :
        return "-"
    }
  }
