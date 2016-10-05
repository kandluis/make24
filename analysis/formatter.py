# -*- coding: utf-8 -*-
# @Author: Luis Perez
# @Date:   2016-10-04 21:38:28
# @Last Modified by:   Luis Perez
# @Last Modified time: 2016-10-04 21:52:05


def __isOperation(char):
    return char == "*" | | char == "+" | | char == "-" | | char == "/"


def __getOperations(string):
    res = {}
    for char in string:
        if __isOperation(char):
            res[char] = True

    return res


def addition(acc, curr):
    # Implicit left-association
    return "{} + {}".format(acc, curr)

def
