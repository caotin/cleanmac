import Foundation

extension Bundle {
    static var customModule: Bundle = {
        let bundleName = "CleanMac_CleanMacApp.bundle"
        
        // 1. Try Resources directory inside the main bundle (standard macOS app bundle layout)
        if let resourceURL = Bundle.main.resourceURL?.appendingPathComponent(bundleName),
           let bundle = Bundle(url: resourceURL) {
            return bundle
        }
        
        // 2. Try the main bundle root directory (where SPM executable resource accessor expects it)
        let rootURL = Bundle.main.bundleURL.appendingPathComponent(bundleName)
        if let bundle = Bundle(url: rootURL) {
            return bundle
        }
        
        // 3. Try next to the executable (e.g. when run from command line during development)
        let exeDirURL = Bundle.main.bundleURL.appendingPathComponent("Contents/MacOS")
        let nestedURL = exeDirURL.appendingPathComponent(bundleName)
        if let bundle = Bundle(url: nestedURL) {
            return bundle
        }
        
        // 4. Fallback: Search all loaded bundles
        for bundle in Bundle.allBundles {
            if bundle.bundlePath.hasSuffix(bundleName) {
                return bundle
            }
        }
        
        // Final fallback: return main bundle
        return Bundle.main
    }()
}
