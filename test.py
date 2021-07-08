import pickle
from functools import lru_cache
from math import sqrt

US_qwerty = [
    '§1234567890-=',
    '\tqwertyuiop[]',
    "asdfghjkl;'\\",
    '`zxcvbnm,./',
    '     '
]

SE_qwerty = [
    '§1234567890-=',
    '\tqwertyuiopå¨',
    "asdfghjklöä'",
    '`zxcvbnm,./',
    '     '
]

row_x_offsets = [
    0,
    0.5,
    2.5 + 0.25,
    1.5 + 0.25 + 0.5,
    4.5 + 0.25 + 0.5,
]


def coordinates(c, other_coordinates=None):
    # special handling for space
    if other_coordinates is not None and c == ' ':
        d = 10000000
        result = None, None
        row_index = len(SE_qwerty) - 1
        row = SE_qwerty[-1]
        for col_index, key in enumerate(row):
            foo = row_x_offsets[row_index] + col_index, row_index
            foo_d = distance(foo, other_coordinates)
            if foo_d < d:
                d = foo_d
                result = foo
            elif foo_d > d:
                break
        assert result != (None, None)
        return result

    # all other keys
    for row_index, row in enumerate(SE_qwerty):
        if c in row:
            return row_x_offsets[row_index] + row.index(c), row_index
    # TODO: should handle shifted keys too, so 4 and $ is the same
    return None


SUFFIX_BADNESS = 2
MAX_BADNESS = 10


def distance(a, b):
    if a is None or b is None:
        return SUFFIX_BADNESS
    x1, y1 = a
    x2, y2 = b
    return sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2))


@lru_cache(maxsize=10000)
def key_distance(c, c2):
    if c == c2:
        return 0
    if c == ' ':
        c, c2 = c2, c
    a = coordinates(c)
    return distance(a, coordinates(c2, a))


diagonal_distance = key_distance('r', '4')
assert key_distance('r', '4') == key_distance('r', '5')
assert key_distance('b', 'b') == 0
assert key_distance('b', 'n') == 1
assert key_distance('b', 'v') == 1
assert key_distance('b', 'g') == diagonal_distance
assert key_distance(' ', 'c') == 1
assert key_distance('c', ' ') == 1
assert key_distance(' ', 'v') == 1
assert key_distance(' ', 'b') == 1
assert key_distance(' ', 'n') == 1
assert key_distance(' ', 'm') == 1
assert key_distance(' ', ' ') == 0


def padded_zip(a, b):
    m = max(len(a), len(b))
    return zip(a.ljust(m, 'X'), b.ljust(m, 'X'))


def badness(s, s2):
    r = 0
    for c, c2 in padded_zip(s, s2):
        r += key_distance(c, c2)
        if r >= MAX_BADNESS:
            return MAX_BADNESS
    return r


assert badness('bananer', 'bananer') == 0
assert badness('nananer', 'bananer') == 1
assert badness('bananer', 'bananew') == 2
assert badness('bananer', 'banane5') == diagonal_distance
assert badness('bananer', 'banane4') == diagonal_distance
assert badness('bananer', 'bananey') == 2

assert badness('aa', 'a') == SUFFIX_BADNESS
assert badness('aaa', 'aa') == SUFFIX_BADNESS
assert badness('aaaa', 'aa') == SUFFIX_BADNESS * 2


def load_products():
    return [
        (name, filter(None, name.lower().split(' ')), price, product_id)
        for name, price, product_id in pickle.load(open('products.pickle', 'rb'))
    ]


products = load_products()


def best_match(s):
    s = s.lower()
    best = None
    best_badness = 10000
    for name, words, price, product_id in products:
        for word in words:
            b = badness(word, s)
            if b < best_badness:
                best_badness = b
                best = name
    return best, best_badness


print(best_match('banan'))
print(best_match('bananer'))
print(best_match('nananer'))
print(best_match('nanan'))

from datetime import datetime
start = datetime.now()
best_match('nanan')

print(datetime.now() - start)
