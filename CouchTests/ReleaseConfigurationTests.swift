import Foundation
import Testing
@testable import Couch

@Suite("Release configuration")
struct ReleaseConfigurationTests {
    @Test
    func legalLinksRejectMissingInvalidAndPlaceholderURLs() throws {
        do {
            try LegalLinks.resolve(privacyRaw: nil, termsRaw: "https://adamsardo.com/couch/terms")
            Issue.record("Expected missing privacy policy URL to throw")
        } catch let error as LegalLinksError {
            #expect(error == .missing(LegalLinks.privacyPolicyKey))
        }
        do {
            try LegalLinks.resolve(
                privacyRaw: "https://adamsardo.com/couch/privacy",
                termsRaw: "https://example.com/terms"
            )
            Issue.record("Expected placeholder terms URL to throw")
        } catch let error as LegalLinksError {
            #expect(error == .placeholder(LegalLinks.termsOfUseKey))
        }
        do {
            try LegalLinks.resolve(
                privacyRaw: "https://adamsardo.com/couch/privacy",
                termsRaw: "not a url"
            )
            Issue.record("Expected invalid terms URL to throw")
        } catch let error as LegalLinksError {
            #expect(error == .invalid(LegalLinks.termsOfUseKey))
        }
        let links = try LegalLinks.resolve(
            privacyRaw: "https://adamsardo.com/couch/privacy",
            termsRaw: "https://adamsardo.com/couch/terms"
        )
        #expect(links.privacyPolicy.host == "adamsardo.com")
        #expect(links.termsOfUse.path == "/couch/terms")
    }

    @Test
    func projectBuildSettingsUseCouchBundleAndExplicitReleaseMetadata() throws {
        let project = try String(contentsOf: repoRoot().appending(path: "Couch.xcodeproj/project.pbxproj"))
        #expect(project.contains("PRODUCT_BUNDLE_IDENTIFIER = com.adamsardo.Couch;"))
        #expect(!project.contains("PRODUCT_BUNDLE_IDENTIFIER = com.adamsardo.Health;"))
        #expect(project.contains("INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = UIInterfaceOrientationPortrait;"))
        #expect(project.contains("INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad"))
        #expect(project.contains("INFOPLIST_KEY_PRIVACY_POLICY_URL = \"https://adamsardo.com/couch/privacy\";"))
        #expect(project.contains("INFOPLIST_KEY_TERMS_OF_USE_URL = \"https://adamsardo.com/couch/terms\";"))
        #expect(!project.contains("INFOPLIST_KEY_PRIVACY_POLICY_URL = \"https://example.com"))
        #expect(!project.contains("INFOPLIST_KEY_TERMS_OF_USE_URL = \"https://example.com"))
    }

    private func repoRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
