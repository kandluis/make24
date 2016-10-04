'''
Algorithm to solve Make24 Game. 

The purpose of the game is to, given 4 numbers and access to the four
basic arithmetic operations (+, -, *, /), create the value 24 using
all four numbers.

The below returns the number of possible, distinct ways, to do this.

@param: numbers [Int List] The set of numbers that need to be used.
@return: [Int] The total number of ways to create 24.
'''
def numberOfSolutions(numbers):
    if len(numbers) != 4:
        print "The game of 24 is played with exactly four numbers"
        return None
    
    numOfWays = numWaysToK(numbers, 24.0)
    print "There are {} ways to make 24 using {}.".format(numOfWays, numbers)
        
        
    return numOfWays

# Calculates the number of ways to make the value k using the list S.
# Solutions are stored in the memoized
# memoized[(S,k)] = results
# K is a Float
# The list of numbers are treated as floats.
memoized = {}
def numWaysToK(S, k):
    # Check for pre-computed solution
    setKey = listHash(S)
    if (setKey, k) in memoized:
        return memoized[(setKey, k)]
    
    # Base case, when the set is a single number, k must match that value
    if len(S) == 1:
        element = S[0]
        res = 1 if k == float(element) else 0
        memoized[(setKey, k)] = res
        return res

    ways = 0
    for (i, integer) in enumerate(S):
        number = float(integer)
        newSet = S[:i] + S[i+1:] 

        # k = number + X or k = X + number
        ways += numWaysToK(newSet, k - number)
        # k = number - X
        ways += numWaysToK(newSet, number - k)
        # k = X - number
        ways += numWaysToK(newSet, k + number)
        # k = X / number
        ways += numWaysToK(newSet, k * number)
        # k = number / X
        if k != 0:
            ways += numWaysToK(newSet, number / k)
        # k = number * X
        if number != 0:
            ways += numWaysToK(newSet, k / number)
        
    
    memoized[(setKey, k)] = ways
    return ways
    
# Heuristic. Given a set, we convert to list, sort, and then convert to
# a tuple and use that as its hash.
def listHash(s):
    return tuple(sorted(s))
