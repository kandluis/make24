# -*- coding: utf-8 -*-
# @Author: Luis Perez
# @Date:   2016-10-04 16:14:34
# @Last Modified by:   Luis Perez
# @Last Modified time: 2016-10-06 00:22:38

'''
Solver for Make 24 Game
'''

import formatter


def numberOfSolutions(numbers, returnWays=False):
    '''
    Algorithm to solve Make24 Game.

    The purpose of the game is to, given 4 numbers and access to the four
    basic arithmetic operations (+, -, *, /), create the value 24 using
    all four numbers.

    The below returns the number of possible, distinct ways, to do this.
    It can additionally return a string of the ways in which it can be done.

    @param: returnWays [Bool] Specify if list of ways should be returned.
    @param: numbers [Int List] The set of numbers that need to be used.
    @param: memoizedResults contains a saved dictionary of results as returned
    # by nubmerOfSolutions
    @return: [Int] The total number of ways to create 24.
    '''
    if len(numbers) != 4:
        print "The game of 24 is played with exactly four numbers"
        return None

    ways = waysToK(numbers, 24.0)

    if returnWays:
        return len(ways), ways
    else:
        return len(ways)


memoizedResults = {}


def waysToK(S, k):
    '''
    Calculates the possible ways to make the value k using the list S.
    Solutions are stored in the memoized
    memoizedResults[(S,k)] = [String List]
    K is a Float
    The list of numbers are treated as floats.
    '''
    # Check for pre-computed solution
    setKey = listHash(S)
    if (setKey, k) in memoizedResults:
        return memoizedResults[(setKey, k)]

    # Base case, when the set is a single number, k must match that value
    if len(S) == 1:
        element = S[0]
        res = [str(element)] if k == float(element) else []
        memoizedResults[(setKey, k)] = res
        return res

    ways = []
    for (i, integer) in enumerate(S):
        newSet = S[:i] + S[i + 1:]

        # k = number + X or k = X + number
        ways += [formatter.addition(el, integer)
                 for el in waysToK(newSet, k - integer)]
        # k = number - X
        ways += [formatter.subtractedFrom(el, integer)
                 for el in waysToK(newSet, integer - k)]
        # k = X - number
        ways += [formatter.subtractFrom(el, integer)
                 for el in waysToK(newSet, k + integer)]

        # k = X / number
        ways += [formatter.divideBy(el, integer)
                 for el in waysToK(newSet, k * integer)]
        # k = number / X
        if k != 0:
            ways += [formatter.dividedBy(el, integer)
                     for el in waysToK(newSet, float(integer) / k)]
        # k = X * number
        if integer != 0:
            ways += [formatter.multiplication(el, integer)
                     for el in waysToK(newSet, k / float(integer))]

    # remove duplicates
    ways = list(set(ways))

    memoizedResults[(setKey, k)] = ways
    return ways


def listHash(s):
    '''
    Heuristic. Given a set, we convert to list, sort, and then convert to
    a tuple and use that as its hash.
    '''
    return tuple(sorted(s))
