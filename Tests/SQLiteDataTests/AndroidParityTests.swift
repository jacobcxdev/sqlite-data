// AndroidParityTests.swift
// Tests verifying SQLiteData CRUD operations work correctly on both platforms.
// These exercise basic GRDB operations that are critical for Android parity.

import Foundation
import SQLiteData
import XCTest

@testable import GRDB

final class SQLiteDataAndroidParityTests: XCTestCase {

  // MARK: - Basic CRUD

  func testBasicInsertAndRead() throws {
    let db = try DatabaseQueue()

    try db.write { db in
      try db.execute(sql: """
        CREATE TABLE items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          value INTEGER NOT NULL DEFAULT 0
        )
        """)
    }

    // Insert
    try db.write { db in
      try db.execute(sql: "INSERT INTO items (name, value) VALUES (?, ?)", arguments: ["alpha", 42])
    }

    // Read back
    let rows = try db.read { db in
      try Row.fetchAll(db, sql: "SELECT * FROM items")
    }

    XCTAssertEqual(rows.count, 1)
    XCTAssertEqual(rows[0]["name"] as String, "alpha")
    XCTAssertEqual(rows[0]["value"] as Int, 42)
  }

  func testUpdateAndDelete() throws {
    let db = try DatabaseQueue()

    try db.write { db in
      try db.execute(sql: """
        CREATE TABLE items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL
        )
        """)
      try db.execute(sql: "INSERT INTO items (name) VALUES (?)", arguments: ["original"])
    }

    // Update
    try db.write { db in
      try db.execute(sql: "UPDATE items SET name = ? WHERE id = ?", arguments: ["updated", 1])
    }

    var rows = try db.read { db in
      try Row.fetchAll(db, sql: "SELECT name FROM items WHERE id = 1")
    }
    XCTAssertEqual(rows[0]["name"] as String, "updated")

    // Delete
    try db.write { db in
      try db.execute(sql: "DELETE FROM items WHERE id = ?", arguments: [1])
    }

    rows = try db.read { db in
      try Row.fetchAll(db, sql: "SELECT * FROM items")
    }
    XCTAssertEqual(rows.count, 0)
  }

  // MARK: - UUID generation in Swift (not sqlite uuid())

  func testUUIDGeneratedInSwift() throws {
    let db = try DatabaseQueue()

    try db.write { db in
      try db.execute(sql: """
        CREATE TABLE records (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL
        )
        """)
    }

    // Generate UUID in Swift — critical for Android where sqlite uuid() doesn't exist
    let id = UUID().uuidString

    try db.write { db in
      try db.execute(
        sql: "INSERT INTO records (id, title) VALUES (?, ?)",
        arguments: [id, "Test Record"]
      )
    }

    let rows = try db.read { db in
      try Row.fetchAll(db, sql: "SELECT * FROM records WHERE id = ?", arguments: [id])
    }

    XCTAssertEqual(rows.count, 1)
    XCTAssertEqual(rows[0]["id"] as String, id)
    XCTAssertEqual(rows[0]["title"] as String, "Test Record")

    // Verify it's a valid UUID
    XCTAssertNotNil(UUID(uuidString: rows[0]["id"] as String))
  }

  func testMultipleUUIDsAreUnique() throws {
    let db = try DatabaseQueue()

    try db.write { db in
      try db.execute(sql: """
        CREATE TABLE records (
          id TEXT PRIMARY KEY,
          seq INTEGER NOT NULL
        )
        """)
    }

    // Insert multiple records with Swift-generated UUIDs
    for i in 0..<10 {
      let id = UUID().uuidString
      try db.write { db in
        try db.execute(
          sql: "INSERT INTO records (id, seq) VALUES (?, ?)",
          arguments: [id, i]
        )
      }
    }

    let count = try db.read { db in
      try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM records")
    }
    XCTAssertEqual(count, 10)
  }

  // MARK: - Date round-trip

  func testDateStorageRoundTrip() throws {
    let db = try DatabaseQueue()

    try db.write { db in
      try db.execute(sql: """
        CREATE TABLE events (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          created_at TEXT NOT NULL
        )
        """)
    }

    let now = Date()
    let formatter = ISO8601DateFormatter()
    let dateString = formatter.string(from: now)

    try db.write { db in
      try db.execute(
        sql: "INSERT INTO events (created_at) VALUES (?)",
        arguments: [dateString]
      )
    }

    let rows = try db.read { db in
      try Row.fetchAll(db, sql: "SELECT created_at FROM events")
    }

    let storedString: String = rows[0]["created_at"]
    let restored = formatter.date(from: storedString)
    XCTAssertNotNil(restored)

    // Allow 1 second tolerance for ISO8601 formatting precision
    XCTAssertEqual(
      restored!.timeIntervalSince1970,
      now.timeIntervalSince1970,
      accuracy: 1.0
    )
  }

  func testGRDBDateColumnRoundTrip() throws {
    let db = try DatabaseQueue()

    try db.write { db in
      try db.execute(sql: """
        CREATE TABLE events (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          created_at DATETIME NOT NULL
        )
        """)
    }

    let now = Date()

    // GRDB natively supports Date via DatabaseValueConvertible
    try db.write { db in
      try db.execute(
        sql: "INSERT INTO events (created_at) VALUES (?)",
        arguments: [now]
      )
    }

    let restored = try db.read { db in
      try Date.fetchOne(db, sql: "SELECT created_at FROM events")
    }
    XCTAssertNotNil(restored)
    XCTAssertEqual(restored!.timeIntervalSince1970, now.timeIntervalSince1970, accuracy: 0.001)
  }
}
