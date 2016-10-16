'''
Analysis engine.

# @Author: Luis Perez
# @Date:   2016-10-04 16:22:28
# @Last Modified by:   Luis Perez
# @Last Modified time: 2016-10-15 19:55:53
'''

from itertools import combinations_with_replacement as combinations
from . import solver


def generateProblem(options=None):
    '''
    A generator for Make24 problems.

    options['maxInt'] [10] - problems only contain numbers <
    options['minInt'] [1] - problems only contain numbers >=
    options['numInts'] [4] - the number of integers to consider
    '''
    options = {} if options is None else options
    maxInt = options['maxInt'] if "maxInt" in options else 10
    minInt = options['minInt'] if "minInt" in options else 1
    num = options['numInts'] if "numInts" in options else 4
    possible = range(minInt, maxInt)

    return combinations(possible, num)


def difficulty(solutions):
    '''
    Lower the score, the easier the problem.
    '''
    return 1.0 / (len(solutions) + 1)


def localResultSet(options=None):
    """Generates the results given the passed options"""
    options = {} if options is None else options
    results = {}
    for problem in generateProblem(options):
        _, solutions = solver.numberOfSolutions(
            problem, returnWays=True)
        results[tuple(problem)] = difficulty(solutions)

    # sort from easiest to hardest
    results = sorted(list(results.iteritems()), key=lambda x: x[1])
    return results
