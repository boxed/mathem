import Cocoa
import Foundation

var SE_qwerty = [
    "§1234567890-=",
    "\tqwertyuiopå¨",
    "asdfghjklöä'",
    "`zxcvbnm,./",
    "     ",
]

func k(s: String) -> UInt8 {
    return s.utf8.first!
}

let SPACE = k(" ")

let row_x_offsets = [
    0.0,
    1+0.5,
    2.5 + 0.25,
    1.5 + 0.25 + 0.5,
    4.5 + 0.25 + 0.5,
]

class Coordinate {
    let x: Double;
    let y: Double;
    
    init(x: Double, y: Double) {
        self.x = x;
        self.y = y;
    }
}

let INVALID_COORDINATE = Coordinate(x: -100, y: -100)

let SUFFIX_BADNESS = 2.0
let MAX_BADNESS = 10.0


func distance(a: Coordinate, b: Coordinate) -> Double {
    return sqrt(pow(b.x - a.x, 2) + pow(b.y - a.y, 2))
}

func coordinates_for_space(other_coordinates: Coordinate) -> Coordinate {
    // special handling for space
    var d = 10000000.0
    var result: Coordinate? = nil
    let row_index = SE_qwerty.count - 1
    let row = SE_qwerty.last!
    for (col_index, _) in row.utf8.enumerate() {
        let foo = Coordinate(x: row_x_offsets[row_index] + Double(col_index), y: Double(row_index))
        let foo_d = distance(foo, b: other_coordinates)
        if foo_d < d {
            d = foo_d
            result = foo
        }
        else if foo_d > d {
            break
        }
    }
    return result!
}

func distance_to_space(c: UInt8) -> Double {
    let a = coordinates(c)
    return distance(a, b: coordinates_for_space(a))
}

func coordinates(c: UInt8) -> Coordinate {
    for (row_index, row) in SE_qwerty.enumerate() {
        let index = row.utf8.indexOf(c)
        if index != nil {
            return Coordinate(x: row_x_offsets[row_index] + Double(row.utf8.startIndex.distanceTo(index!)), y: Double(row_index))
        }
    }
    // TODO: should handle shifted keys too, so 4 and $ is the same
    return INVALID_COORDINATE
}

func key_distance(c: UInt8, c2: UInt8) -> Double {
    if c == c2 {
        return 0
    }
    if c == SPACE {
        // flip arguments
        return key_distance(c2, c2: c)
    }
    if c2 == SPACE {
        return distance_to_space(c)
    }
    let a = coordinates(c)
    return distance(a, b: coordinates(c2))
}
let diagonal_distance = key_distance(k("r"), c2: k("4"))
assert(key_distance(k("r"), c2: k("4")) == key_distance(k("r"), c2: k("5")))
assert(key_distance(k("b"), c2: k("b")) == 0)
assert(key_distance(k("b"), c2: k("n")) == 1)
assert(key_distance(k("b"), c2: k("v")) == 1)
assert(key_distance(k("b"), c2: k("g")) == diagonal_distance)
assert(key_distance(k(" "), c2: k("c")) == 1)
assert(key_distance(k("c"), c2: k(" ")) == 1)
assert(key_distance(k(" "), c2: k("c")) == 1)
assert(key_distance(k(" "), c2: k("v")) == 1)
assert(key_distance(k(" "), c2: k("b")) == 1)
assert(key_distance(k(" "), c2: k("n")) == 1)
assert(key_distance(k(" "), c2: k("m")) == 1)
assert(key_distance(k(" "), c2: k(" ")) == 0)

func badness(s: String, s2: String) -> Double {
    var r = 0.0
    for (c, c2) in zip(s.utf8, s2.utf8) {
        r += key_distance(c, c2: c2)
        if r >= MAX_BADNESS {
            return MAX_BADNESS
        }
    }
    return r + SUFFIX_BADNESS * Double(abs(s.utf8.count - s2.utf8.count))
}

assert(badness("bananer", s2: "bananer") == 0)
assert(badness("nananer", s2: "bananer") == 1)
assert(badness("bananer", s2: "bananew") == 2)
assert(badness("bananer", s2: "banane5") == diagonal_distance)
assert(badness("bananer", s2: "banane4") == diagonal_distance)
assert(badness("bananer", s2: "bananey") == 2)
assert(badness("aa", s2: "a") == SUFFIX_BADNESS)
assert(badness("aaa", s2: "aa") == SUFFIX_BADNESS)
assert(badness("aaaa", s2: "aa") == SUFFIX_BADNESS * 2)

///////////
func printTimeElapsedWhenRunningCode(title:String, operation:()->()) {
    let startTime = CFAbsoluteTimeGetCurrent()
    operation()
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    print("Time elapsed for \(title): \(timeElapsed) s")
}

func timeElapsedInSecondsWhenRunningCode(operation:()->()) -> Double {
    let startTime = CFAbsoluteTimeGetCurrent()
    operation()
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    return Double(timeElapsed)
}
///////////



func best_match(var s: String) -> (String, Double) {
    s = s.lowercaseString
    var best: String = "<No hit>"
    var best_badness = 10000.0
    for product in products {
        for word in product.words {
            if word == "" {
                continue
            }
            let b = badness(word, s2: s)
            if b < best_badness {
                best_badness = b
                best = product.name
            }
        }
    }
    return (best, best_badness)
}


printTimeElapsedWhenRunningCode("foo") {
    let x = best_match("bananer")
    print("\(x)")
}

let y = best_match("banan")
print("\(y)")

