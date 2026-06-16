import Darwin
import Foundation

final class SingleInstanceLock {
    private let lockURL: URL
    private var fileDescriptor: Int32 = -1

    init(lockURL: URL = SingleInstanceLock.defaultLockURL()) {
        self.lockURL = lockURL
    }

    deinit {
        release()
    }

    func acquire() -> Bool {
        guard fileDescriptor == -1 else {
            return true
        }

        do {
            try FileManager.default.createDirectory(
                at: lockURL.deletingLastPathComponent(),
                withIntermediateDirectories: true)
        } catch {
            return false
        }

        let descriptor = open(lockURL.path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
        guard descriptor >= 0 else {
            return false
        }

        guard flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
            close(descriptor)
            return false
        }

        fileDescriptor = descriptor
        return true
    }

    func release() {
        guard fileDescriptor >= 0 else {
            return
        }

        flock(fileDescriptor, LOCK_UN)
        close(fileDescriptor)
        fileDescriptor = -1
    }

    private static func defaultLockURL() -> URL {
        FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/CodexUsageMeter", isDirectory: true)
            .appendingPathComponent("CodexUsageMeter.lock")
    }
}
