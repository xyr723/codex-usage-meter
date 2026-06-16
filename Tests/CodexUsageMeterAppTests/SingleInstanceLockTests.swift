import Foundation
import Testing
@testable import CodexUsageMeterApp

@Test func singleInstanceLockRejectsSecondHolderForSamePath() throws {
    let lockURL = try temporaryLockURL()
    let firstLock = SingleInstanceLock(lockURL: lockURL)
    let secondLock = SingleInstanceLock(lockURL: lockURL)

    #expect(firstLock.acquire() == true)
    #expect(secondLock.acquire() == false)
}

@Test func singleInstanceLockCanBeAcquiredAfterRelease() throws {
    let lockURL = try temporaryLockURL()
    let firstLock = SingleInstanceLock(lockURL: lockURL)

    #expect(firstLock.acquire() == true)
    firstLock.release()

    let secondLock = SingleInstanceLock(lockURL: lockURL)
    #expect(secondLock.acquire() == true)
}

private func temporaryLockURL() throws -> URL {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("CodexUsageMeterTests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory.appendingPathComponent("app.lock")
}
