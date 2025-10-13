//
//  UpdateChecker.swift
//  Translayr
//
//  GitHub Releases 版本检测服务
//

import Foundation
import SwiftUI

/// GitHub Release 响应结构
struct GitHubRelease: Codable {
    let tagName: String
    let name: String
    let htmlUrl: String
    let body: String?
    let publishedAt: String
    let prerelease: Bool

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case htmlUrl = "html_url"
        case body
        case publishedAt = "published_at"
        case prerelease
    }
}

/// 版本检测服务
@MainActor
class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()

    // MARK: - Configuration

    /// GitHub 仓库信息 - 请修改为你的仓库
    private let githubOwner = "YOUR_GITHUB_USERNAME"  // TODO: 修改为你的 GitHub 用户名
    private let githubRepo = "Translayr"              // TODO: 修改为你的仓库名

    // MARK: - Published Properties

    /// 是否有新版本可用
    @Published var hasNewVersion = false

    /// 最新版本信息
    @Published var latestRelease: GitHubRelease?

    /// 正在检查更新
    @Published var isChecking = false

    /// 错误信息
    @Published var errorMessage: String?

    // MARK: - Private Properties

    /// 当前应用版本
    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    /// 上次检查时间的 UserDefaults key
    private let lastCheckKey = "lastUpdateCheckDate"

    private init() {}

    // MARK: - Public Methods

    /// 检查更新
    /// - Parameter silent: 是否静默检查（不显示"已是最新版本"提示）
    func checkForUpdates(silent: Bool = false) {
        guard !isChecking else { return }

        isChecking = true
        errorMessage = nil

        Task {
            do {
                let release = try await fetchLatestRelease()
                self.latestRelease = release

                // 保存检查时间
                UserDefaults.standard.set(Date(), forKey: lastCheckKey)

                // 比较版本
                let hasUpdate = compareVersions(current: currentVersion, latest: release.tagName)
                self.hasNewVersion = hasUpdate

                if hasUpdate {
                    print("🎉 [UpdateChecker] New version available: \(release.tagName)")
                } else {
                    print("✅ [UpdateChecker] Already on latest version: \(currentVersion)")
                }

                self.isChecking = false
            } catch {
                print("❌ [UpdateChecker] Failed to check updates: \(error)")
                self.errorMessage = error.localizedDescription
                self.isChecking = false
            }
        }
    }

    /// 打开 GitHub Releases 页面
    func openReleasesPage() {
        guard let release = latestRelease else {
            // 如果没有获取到 release，打开默认的 releases 页面
            let url = URL(string: "https://github.com/\(githubOwner)/\(githubRepo)/releases")!
            NSWorkspace.shared.open(url)
            return
        }

        // 打开特定版本的页面
        if let url = URL(string: release.htmlUrl) {
            NSWorkspace.shared.open(url)
        }
    }

    /// 检查是否应该自动检查更新（每天检查一次）
    func shouldAutoCheck() -> Bool {
        guard let lastCheck = UserDefaults.standard.object(forKey: lastCheckKey) as? Date else {
            return true // 从未检查过
        }

        let daysSinceLastCheck = Calendar.current.dateComponents([.day], from: lastCheck, to: Date()).day ?? 0
        return daysSinceLastCheck >= 1
    }

    // MARK: - Private Methods

    /// 从 GitHub API 获取最新 release
    private func fetchLatestRelease() async throws -> GitHubRelease {
        let urlString = "https://api.github.com/repos/\(githubOwner)/\(githubRepo)/releases/latest"

        guard let url = URL(string: urlString) else {
            throw UpdateError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UpdateError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw UpdateError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        let release = try decoder.decode(GitHubRelease.self, from: data)

        // 跳过预发布版本
        if release.prerelease {
            throw UpdateError.onlyPrereleaseAvailable
        }

        return release
    }

    /// 比较版本号
    /// - Parameters:
    ///   - current: 当前版本
    ///   - latest: 最新版本
    /// - Returns: 如果最新版本更高，返回 true
    private func compareVersions(current: String, latest: String) -> Bool {
        // 移除 'v' 前缀（如果有）
        let currentClean = current.lowercased().replacingOccurrences(of: "v", with: "")
        let latestClean = latest.lowercased().replacingOccurrences(of: "v", with: "")

        let currentComponents = currentClean.split(separator: ".").compactMap { Int($0) }
        let latestComponents = latestClean.split(separator: ".").compactMap { Int($0) }

        let maxLength = max(currentComponents.count, latestComponents.count)

        for i in 0..<maxLength {
            let currentPart = i < currentComponents.count ? currentComponents[i] : 0
            let latestPart = i < latestComponents.count ? latestComponents[i] : 0

            if latestPart > currentPart {
                return true
            } else if latestPart < currentPart {
                return false
            }
        }

        return false // 版本相同
    }
}

// MARK: - Errors

enum UpdateError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case onlyPrereleaseAvailable

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid GitHub URL"
        case .invalidResponse:
            return "Invalid response from GitHub"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .onlyPrereleaseAvailable:
            return "Only prerelease version available"
        }
    }
}
