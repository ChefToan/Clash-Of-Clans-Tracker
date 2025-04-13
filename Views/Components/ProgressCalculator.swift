// ProgressCalculator.swift
import Foundation

// Protocol for objects that can calculate unit progress
@preconcurrency protocol ProgressCalculator {
    func calculateProgress(_ items: [PlayerItem]) -> Double
}
