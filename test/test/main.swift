import Cocoa
import Foundation

let SE_qwerty = [
    enc("§1234567890+´"),
    enc("\tqwertyuiopå¨"),
    enc("asdfghjklöä'"),
    enc("`zxcvbnm,./"),
    enc("     "),
]

func k(s: String) -> CChar {
    return s.cStringUsingEncoding(encoding)![0]
}

let SPACE = k(" ")

let row_x_offsets = [
    0.0,
    0.5,
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
    for (col_index, _) in row.enumerate() {
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

func distance_to_space(c: CChar) -> Double {
    let a = coordinates(c)
    return distance(a, b: coordinates_for_space(a))
}

func coordinates(c: CChar) -> Coordinate {
    for (row_index, row) in SE_qwerty.enumerate() {
        let index = row.indexOf(c)
        if index != nil {
            return Coordinate(x: row_x_offsets[row_index] + Double(index!), y: Double(row_index))
        }
    }
    // TODO: should handle shifted keys too, so 4 and $ is the same
    return INVALID_COORDINATE
}

func key_distance(c: CChar, c2: CChar) -> Double {
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

func badness(s: [CChar], s2: [CChar]) -> Double {
    var r = 0.0
    for (c, c2) in zip(s, s2) {
        if c == 0 || c2 == 0 {
            // ignore null terminated crap
            continue
        }
        r += key_distance(c, c2: c2)
        if r >= MAX_BADNESS {
            return MAX_BADNESS
        }
    }
    return r + SUFFIX_BADNESS * Double(abs(s.count - s2.count))
}

assert(badness(enc("bananer"), s2: enc("bananer")) == 0)
assert(badness(enc("nananer"), s2: enc("bananer")) == 1)
assert(badness(enc("bananer"), s2: enc("bananew")) == 2)
assert(badness(enc("bananer"), s2: enc("banane5")) == diagonal_distance)
assert(badness(enc("bananer"), s2: enc("banane4")) == diagonal_distance)
assert(badness(enc("bananer"), s2: enc("bananey")) == 2)
assert(badness(enc("aa"), s2: enc("a")) == SUFFIX_BADNESS)
assert(badness(enc("aaa"), s2: enc("aa")) == SUFFIX_BADNESS)
assert(badness(enc("aaaa"), s2: enc("aa")) == SUFFIX_BADNESS * 2)

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



func best_match(s: [CChar]) -> (String, Double) {
    var best: String = "<No hit>"
    var best_badness = 10000.0
    for product in products {
        for word in product.words {
            if word[0] == 0 { // null terminated :(
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


//printTimeElapsedWhenRunningCode("bananer") {
//    let x = best_match("bananer")
//    print("\(x)")
//}


printTimeElapsedWhenRunningCode("nsnsnwe") {
    let s = enc("nsnsnwe".lowercaseString)
    for i in 0..<500 {
        best_match(s)
    }
    let x = best_match(s)
    print("\(x)")
}


