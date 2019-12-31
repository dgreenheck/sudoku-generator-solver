//
//  SudokuCell.swift
//  Sudokube
//
//  Created by Daniel Greenheck on 3/6/19.
//  Copyright © 2019 Max Q Software LLC. All rights reserved.
//

import Foundation

// Represents a single cell in a SudokuBoard or Sudokube
public class SudokuCell {
    // MARK: - Public Members
    
    // Coordinates of cell within the parent sudokube
    var x: Int = 0
    var y: Int = 0
    var z: Int = 0
    
    // True value of the cell
    var truthValue: Int? = nil
    
    // Boolean for determining which cells have already been visited
    // during the solver algorithm
    var visited: Bool = false
    
    // Boolean for defining which cells are preset cells
    var fixed: Bool = false
    
    /// Displayed value of the cell
    public var displayValue: Int?
    
    // MARK: - Initialization
    
    init() {
    }
    
    public init(x _x: Int, y _y: Int, z _z: Int) {
        x = _x
        y = _y
        z = _y
    }
    
    convenience init(x _x: Int, y _y: Int, z _z: Int, userValue: Int?) {
        self.init(x: _x, y: _y, z: _z)
        self.displayValue = userValue
    }
    
    convenience init(x _x: Int, y _y: Int, z _z: Int, userValue: Int?, truthValue: Int) {
        self.init(x: _x, y: _y, z: _z)
        self.displayValue = userValue
    }
    
    // MARK: - Mutators
    
    /// Sets the display value to the true value
    public func showTrueValue() {
        self.displayValue = self.truthValue
    }
    
    // MARK: - Accessors
  
    /// Returns true if the user-entered value does not match the truth value
    /// - returns:True if the user-entered value matches the truth value
    public func isIncorrect() -> Bool {
        // Only validate values the user has entered
        guard self.displayValue != nil else { return false }
        return self.displayValue != self.truthValue
    }
}
