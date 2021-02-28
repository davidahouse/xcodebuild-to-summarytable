import Foundation
import ArgumentParser

struct XcodeBuildToSummaryTable: ParsableCommand {
    @Option(name: .shortAndLong, help: "The derived data folder that contains a test result")
    var derivedDataFolder: String

    @Option(name: .shortAndLong, help: "Set if the derived data path is a root or not")
    var root: Bool
    
    @Option(name: .shortAndLong, help: "Set to the output path to write the results to")
    var outputPath: String
    
    @Option(name: .shortAndLong, help: "Provide a link for the entire summary table")
    var link: String?
    
    mutating func run() throws {
        let derivedData = DerivedData()
        derivedData.root = root
        derivedData.location = URL(fileURLWithPath: derivedDataFolder)
        guard let resultKit = derivedData.recentResultFile() else {
            print("Unable to find XCResult file!")
            return
        }

        // Gather up any compiler errors & warnings
        let findings = gatherFindings(from: resultKit, path: derivedDataFolder)

        // Now see if there are test summaries
        let testSummary = gatherTestSummary(from: resultKit)

        var items = [SummaryTableItem]()
        var warnings = 0
        var errors = 0
        
        for (_, finding) in findings {
            for finding in finding.findings {
                switch finding.category {
                case .error:
                    errors += 1
                case .warning:
                    warnings += 1
                }
            }
        }
        
        var compileBadges = [SummaryTableBadge]()
        if errors > 0 {
            compileBadges.append(SummaryTableBadge(shield: "Compile%20Errors-\(errors)-critical", alt: "\(errors) Compile Errors", logo: nil, style: nil))
        }

        if warnings > 0 {
            compileBadges.append(SummaryTableBadge(shield: "Compile%20Warnings-\(warnings)-yellow", alt: "\(warnings) Compile Warnings", logo: nil, style: nil))
        }
        items.append(SummaryTableItem(title: "Compile Results", link: link, valueString: nil, valueBadges: compileBadges))
        
        var testBadges = [SummaryTableBadge]()
        testBadges.append(SummaryTableBadge(shield: "Unit%20Test%20Count-\(testSummary.allTests)-informational", alt: "Unit Test Count-\(testSummary.allTests)", logo: nil, style: nil))
        testBadges.append(SummaryTableBadge(shield: "Unit%20Tests%20Successful-\(testSummary.successTests)-success", alt: "Unit Tests Successful-\(testSummary.successTests)", logo: nil, style: nil))
        testBadges.append(SummaryTableBadge(shield: "Unit%20Tests%20Failed-\(testSummary.failedTests)-critical", alt: "Unit Tests Failed-\(testSummary.failedTests)", logo: nil, style: nil))
        items.append(SummaryTableItem(title: "Unit Testing", link: link, valueString: nil, valueBadges: testBadges))

        var coverageBadges = [SummaryTableBadge]()
        if let coverage = testSummary.codeCoverage {
            let totalCoverage = Int(coverage.lineCoverage * 100.0)
            if totalCoverage <= 50 {
                coverageBadges.append(SummaryTableBadge(shield: "Code%20Coverage-\(totalCoverage)%25-critical", alt: "Code Coverage \(totalCoverage) Critical", logo: nil, style: nil))
            } else if totalCoverage < 70 {
                coverageBadges.append(SummaryTableBadge(shield: "Code%20Coverage-\(totalCoverage)%25-yellow", alt: "Code Coverage \(totalCoverage)% Warning", logo: nil, style: nil))
            } else if totalCoverage < 90 {
                coverageBadges.append(SummaryTableBadge(shield: "Code%20Coverage-\(totalCoverage)%25-yellowgreen", alt: "Code Coverage \(totalCoverage)% Good", logo: nil, style: nil))
            } else {
                coverageBadges.append(SummaryTableBadge(shield: "Code%20Coverage-\(totalCoverage)%25-success", alt: "Code Coverage \(totalCoverage)% Great", logo: nil, style: nil))
            }
        }
        items.append(SummaryTableItem(title: "Code Coverage", link: link, valueString: nil, valueBadges: coverageBadges))

        do {
            let encoder = JSONEncoder()
            let encodedData = try encoder.encode(items)
            try encodedData.write(to: URL(fileURLWithPath: outputPath))
        } catch {
            throw error
        }
    }
}

XcodeBuildToSummaryTable.main()
