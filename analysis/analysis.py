# -*- coding: utf-8 -*-
# @Author: Luis Perez
# @Date:   2016-10-04 16:22:28
# @Last Modified by:   Luis Perez
# @Last Modified time: 2016-10-06 00:45:35

import solver
from itertools import combinations_with_replacement as combinations


def generateProblem(options={}):
    '''
    A generator for Make24 problems.

    options.maxInt [10] - problems only contain numbers <
    options.minInt [1] - problems only contain numbers >=
    options.numInts [4] - the number of integers to consider
    '''
    maxInt = options.maxInt if "maxInt" in options else 10
    minInt = options.minInt if "minInt" in options else 1
    num = options.numInts if "numInts" in options else 4
    possible = range(minInt, maxInt)

    return combinations(possible, num)


def difficulty(problem, solutions):
    '''
    Lower the score, the easier the problem.
    '''
    return 1.0 / (len(solutions) + 1)


def generateResultSet(options={}):
    results = {}
    for problem in generateProblem(options):
        numSolutions, solutions = solver.numberOfSolutions(
            problem, returnWays=True)
        results[tuple(problem)] = difficulty(problem, solutions)

    # sort from easiest to hardest
    results = sorted(list(results.iteritems()), key=lambda x: x[1])
    return results
