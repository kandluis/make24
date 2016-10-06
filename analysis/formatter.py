# -*- coding: utf-8 -*-
# @Author: Luis Perez
# @Date:   2016-10-04 21:38:28
# @Last Modified by:   Luis Perez
# @Last Modified time: 2016-10-06 00:21:58


def __isOperation(char):
    return char == "*" or char == "+" or char == "-" or char == "/"


def __getOperations(string):
    res = {}
    for char in string:
        if __isOperation(char):
            res[char] = True

    return res


def __tightBinding(ops):
    return (len(ops) == 0 or
            ('+' not in ops and '-' not in ops))


def addition(acc, curr):
    # Implicit left-association
    return "{} + {}".format(acc, curr)


def multiplication(acc, curr):
    if __tightBinding(__getOperations(acc)):
        return "{} * {}".format(acc, curr)
    else:
        return "({}) * {}".format(acc, curr)


def subtractFrom(acc, curr):
    # Implicit left-association
    return "{} - {}".format(acc, curr)


def subtractedFrom(acc, curr):
    if __tightBinding(__getOperations(acc)):
        return "{} - {}".format(curr, acc)
    else:
        return "{} - ({})".format(curr, acc)


def divideBy(acc, curr):
    if __tightBinding(__getOperations(acc)):
        return "{} / {}".format(acc, curr)
    else:
        return "({}) / {}".format(acc, curr)


def dividedBy(acc, curr):
    # Single value
    if len(__getOperations(acc)) == 0:
        return "{} / {}".format(curr, acc)
    else:
        return "{} / ({})".format(curr, acc)
