//
//  SudokubeFace.swift
//
//  Created by Daniel Greenheck on 2/22/19.
//
//  Copyright 2019 Max Q Software Solutions

import Foundation

/// Represents a face of a sudokube
public class SudokuPuzzle: CustomStringConvertible {
    // MARK: - Private Members
    
    // 9x9 array of cells
    private var cells: [[SudokuCell]]
    
    
    // MARK: - Public Members
    
    /// Size of entire face
    public var faceSize: Int {
        get { return 9 }
    }
    
    /// Size of a square
    public var squareSize: Int {
        get { return 3 }
    }
    
    /// Debug description of the face
    public var description: String {
        var str = ""
        
        // Top row
        str += " " + String(repeating: "=", count: 5*self.faceSize + 2*(self.squareSize-1) + (self.faceSize-self.squareSize)) + "  \n"
        
        for row in 0..<self.faceSize {
            // Blank row
            for col in 0..<self.faceSize {
                if (col % self.squareSize) == 0 { str += "|" }
                str += "     |"
            }
            str += "\n"
            
            // Number row
            for col in 0..<self.faceSize {
                if (col % self.squareSize) == 0 { str += "|" }
                if let cellValue = self.getCell(row, col)!.displayValue {
                    str += "  " + String(cellValue) + "  |"
                }
                else {
                    str += "     |"
                }
            }
            str += "\n"
            
            // Blank row
            for col in 0..<self.faceSize {
                if (col % self.squareSize) == 0 { str += "|" }
                str += "     |"
            }
            str += "\n"
            
            // Separator row
            if row < (self.faceSize - 1) {
                for col in 0..<self.faceSize {
                    if (col % self.squareSize) == 0 { str += "|" }
                    if (row % self.squareSize) == (self.squareSize - 1) {
                        str += "=====|"
                    }
                    else {
                        str += "-----|"
                    }
                }
                str += "\n"
            }
        }
        
        // Bottom row
        str += " " + String(repeating: "=", count: 5*self.faceSize + 2*(self.squareSize-1) + (self.faceSize-self.squareSize)) + "  \n"
        
        
        return str
    }
    
    public var debugMode: Bool = false
    
    // MARK: - Initialize
    
    /// Initializes a sudokube face
    /// - parameter generate:If true, generates a random, solved face
    public init(generate: Bool) {
        self.cells = [[SudokuCell]]()
        
        for row in 0..<faceSize {
            var rowCells: [SudokuCell] = [SudokuCell]()
            for col in 0..<faceSize {
                rowCells.append(SudokuCell(x: col, y: row, z: 0))
            }
            self.cells.append(rowCells)
        }
        
        if generate {
            _ = generateRandomSolved()
        }
    }
    
    /// Creates a face given a 9x9 array of cells
    /// - parameter cells:The array of cells to generate the face from. Row is first index, column is second index.
    public init(cells: [[SudokuCell]]) {
        self.cells = cells
    }
    
    /// Create a face with the initial values
    public convenience init(initialValues: [[Int?]]) {
        self.init(generate: false)
        
        for row in 0..<faceSize {
            for col in 0..<faceSize {
                self.getCell(row, col)?.displayValue = initialValues[row][col]
            }
        }
    }

    // MARK: - Solver
    
    /// Generate a randomized, solved board
    /// - returns:True if generation is successful.
    func generateRandomSolved() -> Bool {
        // Fill the board, starting in the middle
        let success = populateCellWithRandomValue(row: 4, col: 4)
            
        if self.debugMode {
            if success {
                print("Solution found!")
            }
            else {
                print("No solution found given initial cell values.")
            }
        }
        
        return success
    }
    
    /// Populate the cell with a random value
    func populateCellWithRandomValue(row: Int, col: Int) -> Bool {
        guard isInBounds(row, col) else { return true }
        // Verified row and column are in bounds so we can guarantee cell exists
        guard !self.getCell(row, col)!.visited else { return true }
        
        self.getCell(row, col)!.visited = true
        
        // If cell is empty, fill the cell with a value
        var candidateFound = false
        if self.getCell(row, col)!.displayValue == nil {
            var candidateValues: [Int] = self.validCandidates(row, col)
            
            // Iterate through list of candidates until it is depleted
            // or a candidate value is found
            while !candidateValues.isEmpty && !candidateFound {
                // Select a candidate at random
                let i = Int.random(in: 0..<candidateValues.count)
                self.getCell(row, col)!.displayValue = candidateValues[i]
                
                // Fill in neighboring cells
                if populateCellWithRandomValue(row: row-1, col: col) &&
                    populateCellWithRandomValue(row: row+1, col: col) &&
                    populateCellWithRandomValue(row: row, col: col-1) &&
                    populateCellWithRandomValue(row: row, col: col+1) {
                    candidateFound = true
                    break
                }
                    // Neighboring cells failed checks, reset cell value and try again
                else {
                    candidateValues.remove(at: i)
                    self.getCell(row, col)!.displayValue = nil
                }
            }
            
            // No candidate found, reset cell value and visited flag and
            // tell calling cell we failed to find a valid candidate
            if !candidateFound {
                self.getCell(row, col)!.displayValue = nil
                self.getCell(row, col)!.visited = false
            }
        }
            // If cell is already filled in, continue filling neighbors
        else {
            if populateCellWithRandomValue(row: row-1, col: col) &&
                populateCellWithRandomValue(row: row+1, col: col) &&
                populateCellWithRandomValue(row: row, col: col-1) &&
                populateCellWithRandomValue(row: row, col: col+1) {
                candidateFound = true
            }
            else {
                self.getCell(row, col)!.visited = false
                candidateFound = false
            }
        }
        
        return candidateFound
    }
    
    /// Returns array of values that are allowed at the row and column
    /// - parameter row:Row index
    /// - parameter col:Column index
    /// - returns:An array containing the allowed values for [row,col]
    func validCandidates(_ row: Int, _ col: Int) -> [Int] {
        guard self.isInBounds(row, col) else { return [Int]() }
        
        var remainingValues: [Int?] = [1,2,3,4,5,6,7,8,9]
        
        // Remove already existing values in the column
        for _col in 0..<faceSize {
            guard _col != col else { continue }
            
            guard let cellValue = self.cells[row][_col].displayValue else { continue }
            remainingValues[cellValue-1] = nil
        }
        
        // Remove already existing values in the row
        for _row in 0..<faceSize {
            guard _row != row else { continue }
            
            guard let cellValue = self.cells[_row][col].displayValue else { continue }
            remainingValues[cellValue-1] = nil
        }
        
        // Remove already existing values in the square
        let rowStart = self.squareSize*(row / self.squareSize)
        let colStart =  self.squareSize*(col / self.squareSize)
        for _row in rowStart...rowStart+2 {
            for _col in colStart...colStart+2 {
                guard _row != row else { continue }
                guard _col != col else { continue }
                
                guard let cell = self.getCell(_row, _col), let cellValue = cell.displayValue else { continue }
                remainingValues[cellValue-1] = nil
            }
        }
        
        // Remove nil values
        return remainingValues.compactMap { $0 }
    }
    
    // MARK: - Puzzle
    
    /// Remove cells to create a puzzle with the specified difficulty
    func puzzlefy(_ minClueCount: Int, _ maxClueCount: Int) -> (Int,Int) {
        // Keep track of faces previously determined to be unique
        var uniqueFaces: Set<[Int]> = Set<[Int]>()
        // Fill in interior cells with their values
        var interiorCells = self.cells.flatMap { $0 }

//        // Reset values of interior cells to the truth values
//        for cell in interiorCells {
//            cell.displayValue = cell.truthValue
//        }
   
        var clueCount = self.getClueCount()
        while (clueCount > minClueCount) && (interiorCells.count > 0) {
            // Pick a random cell and remove it from the list
            let cell = interiorCells.remove(at: Int.random(in: 0..<interiorCells.count))
            let tempValue = cell.displayValue
            cell.displayValue = nil
            // Check if face has a unique solution
            self.fixCellValues()
            
            if !self.hasUniqueSolution(uniqueFaces: &uniqueFaces) {
                cell.displayValue = tempValue
            }
            else {
                clueCount -= 1
            }
            self.resetFixed()
        }
   
        // Final check for unique solution
        if !self.hasUniqueSolution(uniqueFaces: &uniqueFaces) {
            clueCount = 81
        }
        
        return (clueCount,self.evaluateCostFunction())
    }
    
    /// Returns true if the board is solved and valid
    /// - returns:True if the face is solved and valid.
    func isSolved() -> Bool {
        
        // Check that all cells are filled
        for row in 0..<self.faceSize {
            for col in 0..<self.faceSize {
                if self.getCell(row, col)?.displayValue == nil {
                    return false
                }
            }
        }
        
        // Verify each square is self-consistent and complete
        for squareRow in 0..<self.squareSize {
            for squareCol in 0..<self.squareSize {
                if !self.isSquareValid(squareRow, squareCol) {
                    return false
                }
            }
        }
        
        // Verify each row is self-consistent and complete
        for row in 0..<self.faceSize {
            if !self.isRowValid(row) {
                return false
            }
        }
        
        // Verify each column is self-consistent and complete
        for col in 0..<self.faceSize {
            if !self.isColumnValid(col) {
                return false
            }
        }
        
        return true
    }
    
    /// Determines if the puzzle has a unique solution
    /// - parameter uniqueFaces:Set of faces that are known to be unique. This set is used to prevent checking faces which have previously been determined to be unique.
    /// - returns:True if the puzzle has a unique solution
    public func hasUniqueSolution(uniqueFaces: inout Set<[Int]>) -> Bool {
        // Check if face was already determined to be unique
        guard !uniqueFaces.contains(self.flatten()) else { return true }
        
        // Otherwise, need to search solution space
        var solutionCount = 0
        self.numberOfSolutions(0, &solutionCount)
        if solutionCount == 1 {
            uniqueFaces.insert(self.flatten())
        }
        
        return (solutionCount == 1)
    }
    
    /// Recursive function for determining the number of solutions in the puzzle
    /// - parameter cellIndex:The cell index to start searching at
    /// - parameter initialNumSolutions:Previous number of found solutions
    /// - returns:0 if no solutions, 1 if the face has a unique solution, and 2 if the puzzle has 2 or more solutions.
    private func numberOfSolutions(_ cellIndex: Int, _ solutionCount: inout Int) {
        // If already found two solutions, stop looking
        guard solutionCount <= 1 else { return }
 
        // Index is beyond the last cell, check the solution
        if cellIndex == self.faceSize*self.faceSize {
            if isSolved() {
                solutionCount += 1
            }
        }
        else {
            let row = cellIndex / 9
            let col = cellIndex % 9
            let cell = self.getCell(row, col)!
            
            // Only update values of non-fixed cells
            if !cell.fixed {
                cell.displayValue = nil
                
                // Get all possible values that can go in this cell
                let candidates = self.validCandidates(row,col)
                // If no candidates, no solution
                if candidates.count == 0 {
                    return
                }
                
                // Search solution space for each candidate
                for value in candidates {
                    cell.displayValue = value
                    self.numberOfSolutions(cellIndex + 1, &solutionCount)
                    cell.displayValue = nil
                    
                    // If more than one solution found, exit early
                    if solutionCount > 1 {
                        return
                    }
                }
            }
            else {
                self.numberOfSolutions(cellIndex + 1, &solutionCount)
            }
        }
    }
    
    /// Flattens and maps the 2D array of cells into a 1D array of cell values.
    /// Nil values are replaced with 0.
    /// - returns:An array of cell values.
    func flatten() -> [Int] {
        let cellArray1D: [SudokuCell] = self.cells.flatMap { $0 }
        return cellArray1D.map { $0.displayValue ?? 0 }
    }
    
    /// Returns a 9x9 array containing the display values
    /// - returns:9x9 array containing the display values
    func toArray() -> [[Int?]] {
        var clues = [[Int?]]()
        for row in 0..<faceSize {
            var rowCells: [Int?] = [Int?]()
            for col in 0..<faceSize {
                let cell = self.getCell(row, col)!
                rowCells.append(cell.displayValue)
            }
            clues.append(rowCells)
        }
        return clues
    }
    
    // MARK: - Cost Function
    
    /// Evaluates the cost function and returns the result. The cost function
    /// is minimized by meeting the following criteria
    ///     1. Length of consecutive numbers in a row/column
    ///     2. Adjacent numbers
    ///     3. Uneven distribution of numbers in 3x3 squares
    ///     4. Uneven distribution across rows
    ///     5. Uneven distribution across columns
    internal func evaluateCostFunction() -> Int {
        let consecutiveCost = 2*evaluateConsecutiveNumberCost()
        let adjacencyCost = evaluateAdjacencyCost()
        let squareDistributionCost = evaluateSquareDistributionCost()
        let rowDistributionCost = evaluateRowDistributionCost()
        let columnDistributionCost = evaluateColumnDistributionCost()
        
        let totalCost = consecutiveCost + adjacencyCost + squareDistributionCost +
            rowDistributionCost + columnDistributionCost
        
        return totalCost
    }
    
    private func evaluateConsecutiveNumberCost() -> Int {
        var cost = 0
        
        // Horizontal lines
        for row in 0..<self.faceSize {
            var lineLength = 0
            for col in 0..<self.faceSize {
                guard let cell = self.getCell(row, col) else { continue }
                
                if cell.displayValue == nil {
                    if lineLength > 1 {
                        cost += lineLength*lineLength*lineLength
                    }
                    lineLength = 0
                }
                else {
                    lineLength += 1
                }
            }
            
            // Don't want lines longer than 3 numbers
            if lineLength < 4 {
                cost += lineLength*lineLength*lineLength
            }
            else {
                return 99999
            }
        }
  
        for col in 0..<self.faceSize {
            var lineLength = 0
            for row in 0..<self.faceSize {
                guard let cell = self.getCell(row, col) else { continue }
                
                if cell.displayValue == nil {
                    if lineLength > 1 {
                        cost += lineLength*lineLength*lineLength
                    }
                    lineLength = 0
                }
                else {
                    lineLength += 1
                }
            }
            cost += lineLength*lineLength*lineLength
            
            // Don't want lines longer than 3 numbers
            if lineLength < 4 {
                cost += lineLength*lineLength*lineLength
            }
            else {
                return 99999
            }
        }
        
        return cost
    }
 
    private func evaluateAdjacencyCost() -> Int {
        var cost: Int = 0
        for row in 0..<self.faceSize {
            for col in 0..<self.faceSize {
                // Check cells that have a non-nil value
                guard let cell = self.getCell(row, col) else { continue }
                guard cell.displayValue != nil else { continue }
                
                // Find the number of adjacent, non-nil cells
                var adjacencyCount = 0
                if let topCell = self.getCell(row - 1, col), topCell.displayValue != nil {
                    adjacencyCount += 1
                }
                if let downCell = self.getCell(row + 1, col), downCell.displayValue != nil {
                    adjacencyCount += 1
                }
                if let leftCell = self.getCell(row, col - 1), leftCell.displayValue != nil {
                    adjacencyCount += 1
                }
                if let rightCell = self.getCell(row, col + 1), rightCell.displayValue != nil {
                    adjacencyCount += 1
                }
                cost += adjacencyCount*adjacencyCount*adjacencyCount
            }
        }
        return cost
    }
    
    private func evaluateSquareDistributionCost() -> Int {
        var cost = 0
        
        for squareRow in 0..<self.squareSize {
            for squareCol in 0..<self.squareSize {
                let startRow = squareRow*self.squareSize
                let startCol = squareCol*self.squareSize
                var count = 0
                for row in startRow..<(startRow + 3) {
                    for col in startCol..<(startCol + 3) {
                        guard let cell = self.getCell(row, col) else { continue }
                        guard cell.displayValue != nil else { continue }
                        count += 1
                    }
                }
                cost += count*count
            }
        }
        return cost / 9
    }
    
    private func evaluateRowDistributionCost() -> Int {
        var cost = 0
        for row in 0..<self.faceSize {
            var count = 0
            for col in 0..<self.faceSize {
                guard let cell = self.getCell(row, col) else { continue }
                guard cell.displayValue != nil else { continue }
                count += 1
            }
            cost += count*count
        }
        return cost / 9
    }
    
    private func evaluateColumnDistributionCost() -> Int {
        var cost = 0
        for col in 0..<self.faceSize {
            var count = 0
            for row in 0..<self.faceSize {
                guard let cell = self.getCell(row, col) else { continue }
                guard cell.displayValue != nil else { continue }
                count += 1
            }
            cost += count*count
        }
        return cost / 9
    }
    
    // MARK: - Accessors
    
    /// Returns the cell at the row and column
    /// - parameter row:Row index
    /// - parameter col:Column index
    /// - returns:The cell at [row,col]. Returns nil if row/col are out of bounds.
    func getCell(_ row: Int, _ col: Int) -> SudokuCell? {
        guard isInBounds(row, col) else { return nil }
        
        return cells[row][col]
    }
    
    /// Returns the number of clues (non-empty spaces) currently shown
    /// - returns:The number of clues
    func getClueCount() -> Int {
        var clueCount = 0
        for row in 0..<self.faceSize {
            for col in 0..<self.faceSize {
                guard let cell = self.getCell(row, col) else { continue }
                guard cell.displayValue != nil else { continue }
                clueCount += 1
            }
        }
        return clueCount
    }
    
    /// Check if the row contains the value argument
    /// - parameter row:Row index
    /// - parameter value:Value to search for
    /// - returns:True if the row contains the value
    func rowContainsValue(_ row: Int, value: Int) -> Bool {
        guard isInBounds(row, 1) else { return false }
        
        for col in 0..<faceSize {
            if self.cells[row][col].displayValue == value {
                return true
            }
        }
        return false
    }
    
    /// Check if the column contains the value argument
    /// - parameter col:Row index
    /// - parameter value:Value to search for
    /// - returns:True if the column contains the value
    func columnContainsValue(_ col: Int, value: Int) -> Bool {
        guard isInBounds(1, col) else { return false }
        
        for row in 0..<faceSize {
            if self.cells[row][col].displayValue == value {
                return true
            }
        }
        return false
    }
    
    /// Check if the square containing the cell at [row,col] contains the value argument
    /// - parameter row:Cell row index
    /// - parameter col:Cell column index
    /// - parameter value:Value to search for
    /// - returns:True if the square contains the value
    func squareContainsValue(_ row: Int, _ col: Int, value: Int) -> Bool {
        guard isInBounds(row, col) else { return false }
        
        // Determine what square the cell is in
        let rowStart = squareSize*(row / squareSize)
        let colStart = squareSize*(col / squareSize)
        let rowEnd = rowStart + (squareSize - 1)
        let colEnd = colStart + (squareSize - 1)
        
        for row in rowStart...rowEnd {
            for col in colStart...colEnd {
                if self.cells[row][col].displayValue == value {
                    return true
                }
            }
        }
        
        return false
    }

    // MARK: - Validity Checks
    
    /// Checks to see if the row and column are within the boards of the board
    /// - parameter row:Row index
    /// - parameter col:Column index
    func isInBounds(_ row: Int, _ col: Int) -> Bool {
        guard (row >= 0 && row < self.faceSize) else { return false }
        guard (col >= 0 && col < self.faceSize) else { return false }
    
        return true
    }
    
    /// Verify this row is valid and self-consistent (e.g. numbers 1-N are represented and not repeated)
    /// - parameter row:Row index
    func isRowValid(_ row: Int) -> Bool {
        guard isInBounds(row, 1) else { return false }
        
        var remainingValues = Array<Int>(1...faceSize)
        
        for col in 0..<faceSize {
            guard let cellValue = self.getCell(row, col)!.displayValue else {
                if self.debugMode {
                    print("Validation failed on row \(row+1): Cell (\(row+1),\(col+1)) is empty.")
                }
                return false
            }
            
            // Remove value from list of remaining values
            if let index = remainingValues.firstIndex(of: cellValue) {
                remainingValues.remove(at: index)
            }
            else {
                if self.debugMode {
                    print("Validation failed on row \(row+1): Row \(row+1) contains repeating value.")
                }
                return false
            }
        }
        
        // We expect no remaining values once all cells have been checked
        return (remainingValues.count == 0)
    }
    
    /// Verify this column is valid and self-consistent (e.g. numbers 1-N are represented and not repeated)
    /// - parameter col:Column index
    func isColumnValid(_ col: Int) -> Bool {
        guard isInBounds(1, col) else { return false }
        
        var remainingValues = Array<Int>(1...faceSize)
        
        for row in 0..<faceSize {
            guard let cellValue = self.getCell(row, col)!.displayValue else {
                if self.debugMode {
                    print("Validation failed on column \(col+1): Cell (\(row+1),\(col+1)) is empty.")
                }
                return false
            }
            
            // Remove value from list of remaining values
            if let index = remainingValues.firstIndex(of: cellValue) {
                remainingValues.remove(at: index)
            }
            else {
                if self.debugMode {
                    print("Validation failed on column \(col+1): Column \(col+1) contains repeating value.")
                }
                return false
            }
        }
        
        // We expect no remaining values once all cells have been checked
        return (remainingValues.count == 0)
    }
    
    /// Verify this grid square is valid and self-consistent (e.g. numbers 1-N are all represented and not repeated)
    /// - parameter squareRow:Row index of the square (0...2)
    /// - parameter squareCol:Column index of the square (0...2)
    func isSquareValid(_ squareRow: Int, _ squareCol: Int) -> Bool {
        var remainingValues = Array<Int>(1...faceSize)
        
        let rowStart = squareRow*squareSize
        let colStart = squareCol*squareSize
        let rowEnd = rowStart + (squareSize - 1)
        let colEnd = colStart + (squareSize - 1)
        
        for row in rowStart...rowEnd {
            for col in colStart...colEnd {
                guard let cellValue = self.getCell(row, col)!.displayValue else {
                    if self.debugMode {
                        print("Validation failed on square (\(squareRow+1),\(squareCol+1)): Cell (\(row+1),\(col+1)) is empty.")
                    }
                    return false
                }
                
                // Remove value from list of remaining values
                if let index = remainingValues.firstIndex(of: cellValue) {
                    remainingValues.remove(at: index)
                }
                else {
                    if self.debugMode {
                        print("Validation failed on square (\(squareRow+1),\(squareCol+1)): Square contains repeating value (\(cellValue))")
                    }
                    return false
                }
            }
        }
        
        // We expect no remaining values once all cells have been checked
        return (remainingValues.count == 0)
    }
    
    /// Returns true if the cell is 180 degrees rotationally symmetric
    func isSymmetric() -> Bool {
        for row in 0..<faceSize {
            for col in 0..<faceSize {
                // Find all empty cells
                if getCell(row, col)?.displayValue == nil {
                    let mirrorRow = faceSize - 1 - row
                    let mirrorCol = faceSize - 1 - col
                    // Verify that mirrored cell is also empty
                    if getCell(mirrorRow, mirrorCol)?.displayValue != nil {
                        return false
                    }
                }
            }
        }
        return true
    }
    
    // MARK: - Mutators
    
    /// Set the value of the cell at [row,col]
    func setCellValue(to value: Int?, _ row: Int, _ col: Int) {
        guard isInBounds(row, col) else { return }
        self.cells[row][col].displayValue = value
    }
    
    /// Clears all cell values
    /// - parameter ignoreFixed:If true, fixed cells are not cleared.
    func clear(ignoreFixed: Bool) {
        for row in 0..<faceSize {
            for col in 0..<faceSize {
                let cell = self.getCell(row, col)!
                
                if ignoreFixed && cell.fixed {
                }
                else {
                    cell.displayValue = nil
                }
            }
        }
    }
    
    /// Reset the visited flags for each square
    func resetVisited() {
        for row in 0..<faceSize {
            for col in 0..<faceSize {
                cells[row][col].visited = false
            }
        }
    }
    
    /// Sets all cells with non-nil values to fixed
    func fixCellValues() {
        for row in 0..<self.faceSize {
            for col in 0..<self.faceSize {
                if let cell = self.getCell(row,col), cell.displayValue != nil {
                    cell.fixed = true
                }
            }
        }
    }
    
    /// Sets the fixed property of all cells to false
    func resetFixed() {
        for row in 0..<self.faceSize {
            for col in 0..<self.faceSize {
                if let cell = self.getCell(row,col) {
                    cell.fixed = false
                }
            }
        }
    }
}
