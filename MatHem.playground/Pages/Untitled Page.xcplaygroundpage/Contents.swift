import Cocoa

var SE_qwerty = [
    "§1234567890-=",
    "\tqwertyuiopå¨",
    "asdfghjklöä'",
    "`zxcvbnm,./",
    "     ",
]

var row_x_offsets = [
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
    for (col_index, _) in row.characters.enumerate() {
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

func distance_to_space(c: Character) -> Double {
    let a = coordinates(c)
    return distance(a, b: coordinates_for_space(a))
}

func coordinates(c: Character) -> Coordinate {
    for (row_index, row) in SE_qwerty.enumerate() {
        let index = row.characters.indexOf(c)
        if index != nil {
            return Coordinate(x: row_x_offsets[row_index] + Double(row.startIndex.distanceTo(index!)), y: Double(row_index))
        }
    }
    // TODO: should handle shifted keys too, so 4 and $ is the same
    assert(false)
}

func key_distance(c: Character, c2: Character) -> Double {
    if c == c2 {
        return 0
    }
    if c == " " {
        // flip arguments
        return key_distance(c2, c2: c)
    }
    if c2 == " " {
        return distance_to_space(c)
    }
    let a = coordinates(c)
    return distance(a, b: coordinates(c2))
}
let diagonal_distance = key_distance("r", c2: "4")
assert(key_distance("r", c2: "4") == key_distance("r", c2: "5"))
assert(key_distance("b", c2: "b") == 0)
assert(key_distance("b", c2: "n") == 1)
assert(key_distance("b", c2: "v") == 1)
assert(key_distance("b", c2: "g") == diagonal_distance)
assert(key_distance(" ", c2: "c") == 1)
assert(key_distance("c", c2: " ") == 1)
assert(key_distance(" ", c2: "c") == 1)
assert(key_distance(" ", c2: "v") == 1)
assert(key_distance(" ", c2: "b") == 1)
assert(key_distance(" ", c2: "n") == 1)
assert(key_distance(" ", c2: "m") == 1)
assert(key_distance(" ", c2: " ") == 0)
