// ProgressCalculator.swift
import Foundation

// Protocol for objects that can calculate unit progress
protocol ProgressCalculator {
    func calculateProgress(_ items: [PlayerItem]) -> Double
}
