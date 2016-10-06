# -*- coding: utf-8 -*-
# @Author: Luis Perez
# @Date:   2016-10-04 16:22:28
# @Last Modified by:   Luis Perez
# @Last Modified time: 2016-10-06 00:12:30

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


def easeOfSolution(problem, solutions):
    '''
    Lower the score, the easier the problem
    '''
    return len(solutions)


def generateResultSet(options={}):
    results = {}
    for problem in generateProblem(options):
        numSolutions, solutions, solutionSet = solver.numberOfSolutions(
            problem, returnWays=True)
        results[tuple(problem)] = easeOfSolution(problem, solutions)

    # sort from easiest to hardest (high ease to low ease)
    results = sorted(list(results.iteritems()), key=lambda x: -1 * x[1])
    return results
