//
//  main.swift
//  SudokuSolver
//
//  Created by Daniel Greenheck on 12/31/19.
//  Copyright © 2019 Daniel Greenheck. All rights reserved.
//

import Foundation

// Generate a new puzzle
let puzzle = SudokuPuzzle(generate: true)
print(puzzle.description)
puzzle.puzzlefy(36, 40)
print(puzzle.description)



