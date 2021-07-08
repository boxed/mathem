import Foundation

struct ProductJson: Codable {
    let name: String
    let price: Double
    let id: String
}

public class Product {
    let name: String
    let price: Double
    let product_id: String
    let words: [String]
    
    init(name: String, price: Double, product_id: String) {
        self.name = name
        self.price = price
        self.product_id = product_id
        self.words = name.lowercased().components(separatedBy: " ")//.map(enc)
    }
}

let data = try Data(contentsOf: URL(fileURLWithPath: "/Users/boxed/Projects/mathem/products.json"), options: .mappedIfSafe)
let decoder = JSONDecoder()
let products_json: [ProductJson] = try! decoder.decode([ProductJson].self, from: data)
var products: [Product] = []
for p in products_json {
    products.append(Product(name: p.name, price: p.price, product_id: p.id))
}

//////

var SE_qwerty = [
    "§12345678900+´",
    "\tqwertyuiopå¨",
    "asdfghjklöä'",
    "<zxcvbnm,.-",
    "     ",
]

var row_x_offsets = [
    0.0,
    0.5,
    2.5 + 0.25,
    1.5 + 0.25 + 0.5,
    4.5 + 0.25 + 0.5,
]

struct Coordinate {
    let x: Double;
    let y: Double;
}

let SUFFIX_BADNESS = 2.0
let MAX_BADNESS = 10.0


func distance(_ a: Coordinate, _ b: Coordinate) -> Double {
    return sqrt(pow(b.x - a.x, 2) + pow(b.y - a.y, 2))
}

func coordinates_for_space(_ other_coordinates: Coordinate) -> Coordinate {
    // special handling for space
    var d = 10000000.0
    var result: Coordinate? = nil
    let row_index = SE_qwerty.count - 1
    let row = SE_qwerty.last!
    for (col_index, _) in row.enumerated() {
        let foo = Coordinate(x: row_x_offsets[row_index] + Double(col_index), y: Double(row_index))
        let foo_d = distance(foo, other_coordinates)
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

func distance_to_space(_ c: Character) -> Double {
    let a = coordinates(c)
    return distance(a, coordinates_for_space(a))
}

func coordinates(_ c: Character) -> Coordinate {
    if c == "%" {
        return coordinates("5")
    }
    if c == "&" {
        return coordinates("6")
    }
    if c == "/" {
        return coordinates("7")
    }
    if c == "(" {
        return coordinates("8")
    }
    if c == ")" {
        return coordinates("9")
    }
    if c == "é" {
        return coordinates("e")
    }
    if c == ":" {
        return coordinates(".")
    }

    for (row_index, row) in SE_qwerty.enumerated() {
        if let index = row.firstIndex(of:c) {
            return Coordinate(x: row_x_offsets[row_index] + Double(row.distance(from: row.startIndex, to:index)), y: Double(row_index))
        }
    }

    // TODO: should handle shifted keys too, so 4 and $ is the same
    return Coordinate(x:-100, y: -100)
}

// Non Recursive
func memoize<T: Hashable, U>(work: @escaping (T)->U) -> (T)->U {
    var memo = Dictionary<T, U>()

    return { x in
        if let q = memo[x] { return q }
        let r = work(x)
        memo[x] = r
        return r
    }
}

func _key_distance(_ c: Character, _ c2: Character) -> Double {
    if c == c2 {
        return 0
    }
    if c == " " {
        // flip arguments
        return key_distance(c2, c)
    }
    if c2 == " " {
        return distance_to_space(c)
    }
    let a = coordinates(c)
    return distance(a, coordinates(c2))
}

struct X : Hashable {
    var a : Character
    var b : Character
}

let mem_key_distance = memoize {
    (_ x : X) in
    _key_distance(x.a, x.b)
}

func key_distance(_ c: Character, _ c2: Character) -> Double {
    return mem_key_distance(X(a: c, b: c2))
}


let diagonal_distance = key_distance("r", "4")
assert(key_distance("r", "4") == key_distance("r", "5"))
assert(key_distance("b", "b") == 0)
assert(key_distance("b", "n") == 1)
assert(key_distance("b", "v") == 1)
assert(key_distance("b", "g") == diagonal_distance)
assert(key_distance(" ", "c") == 1)
assert(key_distance("c", " ") == 1)
assert(key_distance(" ", "c") == 1)
assert(key_distance(" ", "v") == 1)
assert(key_distance(" ", "b") == 1)
assert(key_distance(" ", "n") == 1)
assert(key_distance(" ", "m") == 1)
assert(key_distance(" ", " ") == 0)

func badness(_ s: String, _ s2: String) -> Double {
    var r = 0.0
    for (c, c2) in zip(s, s2) {
        r += key_distance(c, c2)
        if r >= MAX_BADNESS {
            return MAX_BADNESS
        }
    }
    return r + SUFFIX_BADNESS * Double(abs(s.count - s2.count))
}

assert(badness("bananer", "bananer") == 0)
assert(badness("nananer", "bananer") == 1)
assert(badness("bananer", "bananew") == 2)
assert(badness("bananer", "banane5") == diagonal_distance)
assert(badness("bananer", "banane4") == diagonal_distance)
assert(badness("bananer", "bananey") == 2)
assert(badness("aa", "a") == SUFFIX_BADNESS)
assert(badness("aaa", "aa") == SUFFIX_BADNESS)
assert(badness("aaaa", "aa") == SUFFIX_BADNESS * 2)

///////////
func printTimeElapsedWhenRunningCode(_ title: String, _ operation: ()->()) {
    let startTime = CFAbsoluteTimeGetCurrent()
    operation()
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    print("Time elapsed for \(title): \(timeElapsed) s")
}

func timeElapsedInSecondsWhenRunningCode(_ operation: ()->()) -> Double {
    let startTime = CFAbsoluteTimeGetCurrent()
    operation()
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    return Double(timeElapsed)
}
///////////



func best_match(_ inS: String) -> (String, Double) {
    let s = inS.lowercased()
    var best: String = "<No hit>"
    var best_badness = 10000.0
    for product in products {
        for word in product.words {
            let b = badness(word, s)
            if b < best_badness {
                best_badness = b
                best = product.name
            }
        }
    }
    return (best, best_badness)
}

printTimeElapsedWhenRunningCode("foo") {
    _ = best_match("nsnsnwe")
}
