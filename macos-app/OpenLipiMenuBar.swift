import Cocoa
import Carbon.HIToolbox

// MARK: - Main Entry Point
@main
struct OpenLipiMenuBarApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        
        // Setup signal handlers to kill binary on unexpected termination
        setupSignalHandlers()
        
        app.run()
    }
    
    static func setupSignalHandlers() {
        // Handle SIGTERM (normal termination)
        signal(SIGTERM) { _ in
            AppDelegate.shared?.cleanupAndExit()
        }
        
        // Handle SIGINT (Ctrl+C)
        signal(SIGINT) { _ in
            AppDelegate.shared?.cleanupAndExit()
        }
        
        // Handle SIGHUP (terminal hangup)
        signal(SIGHUP) { _ in
            AppDelegate.shared?.cleanupAndExit()
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var shared: AppDelegate?
    
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var layoutsMenu: NSMenu!
    private var statusMenuItem: NSMenuItem!
    private var pauseMenuItem: NSMenuItem!
    
    private var engineManager: EngineManager!
    private var layoutManager: LayoutManager!
    private var statusBarManager: StatusBarManager!
    
    override init() {
        super.init()
        AppDelegate.shared = self
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        setupManagers()
        setupMenu()
        
        layoutManager.refreshLayoutsMenu()
        engineManager.start()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        cleanupAndExit()
    }
    
    func cleanupAndExit() {
        engineManager?.stop()
        exit(0)
    }
    
    deinit {
        engineManager?.stop()
    }
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.title = ""
            button.toolTip = "OpenLipi"
        }
        statusBarManager = StatusBarManager(statusItem: statusItem)
    }
    
    private func setupManagers() {
        engineManager = EngineManager()
        layoutManager = LayoutManager()
        
        engineManager.onStatusChange = { [weak self] running, enabled in
            self?.statusBarManager.updateStatus(running: running, enabled: enabled)
            self?.updateStatusMenuItem(running: running, enabled: enabled)
            self?.updatePauseMenuItem(enabled: enabled)
        }
        
        layoutManager.onBinaryChanged = { [weak self] in
            self?.engineManager.restart()
        }
        
        layoutManager.onLayoutsFolderChanged = { [weak self] in
            self?.layoutManager.refreshLayoutsMenu()
            self?.engineManager.restart()
        }
        
        layoutManager.onLayoutChanged = { [weak self] in
            self?.engineManager.restart()
        }
    }
    
    private func setupMenu() {
        menu = NSMenu()
        statusItem.menu = menu
        
        menu.addItem(NSMenuItem(title: "Select Binary…", action: #selector(selectBinary), keyEquivalent: "b"))
        menu.addItem(NSMenuItem(title: "Choose Layouts Folder…", action: #selector(selectLayoutsFolder), keyEquivalent: "l"))
        menu.addItem(NSMenuItem.separator())
        
        let layoutsItem = NSMenuItem(title: "Layouts", action: nil, keyEquivalent: "")
        layoutsMenu = NSMenu()
        layoutsItem.submenu = layoutsMenu
        layoutManager.layoutsMenu = layoutsMenu
        menu.addItem(layoutsItem)
        
        menu.addItem(NSMenuItem.separator())
        statusMenuItem = NSMenuItem(title: "Status: Stopped", action: nil, keyEquivalent: "")
        menu.addItem(statusMenuItem)
        pauseMenuItem = NSMenuItem(title: "Pause", action: #selector(togglePause), keyEquivalent: "p")
        menu.addItem(pauseMenuItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
    }
    
    private func updateStatusMenuItem(running: Bool, enabled: Bool) {
        let mappingText = enabled ? "ON" : "OFF"
        statusMenuItem.title = running ? "Status: Running (\(mappingText))" : "Status: Stopped"
    }
    
    private func updatePauseMenuItem(enabled: Bool) {
        pauseMenuItem.title = enabled ? "Pause" : "Resume"
    }
    
    @objc private func selectBinary() {
        layoutManager.selectBinary()
    }
    
    @objc private func selectLayoutsFolder() {
        layoutManager.selectLayoutsFolder { [weak self] in
            self?.layoutManager.refreshLayoutsMenu()
        }
    }
    
    @objc private func togglePause() {
        engineManager.togglePause()
    }
    
    @objc private func quitApp() {
        engineManager.stop()
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Engine Manager
class EngineManager {
    private var process: Process?
    private var isMappingEnabled = true
    var onStatusChange: ((Bool, Bool) -> Void)?
    
    private let userDefaults = UserDefaults.standard
    private let binaryPathKey = "openlipi.binaryPath"
    private let lastLayoutKey = "openlipi.lastLayout"
    
    func start() {
        if let proc = process, proc.isRunning { return }
        
        guard let binary = getBinaryPath() else {
            showAlert("Select the OpenLipi binary first.")
            return
        }
        
        let layoutPath = getLayoutPath()
        guard let layout = layoutPath else {
            showAlert("Select a layout first.")
            return
        }
        
        // Debug logging
        print("Binary path: \(binary)")
        print("Layout path: \(layout)")
        
        // Verify binary exists and is executable
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: binary) else {
            showAlert("Binary not found at: \(binary)")
            return
        }
        
        guard fileManager.isExecutableFile(atPath: binary) else {
            showAlert("Binary is not executable. Try: chmod +x \(binary)")
            return
        }
        
        // Save layout if not already saved
        if userDefaults.string(forKey: lastLayoutKey) == nil {
            userDefaults.set(layout, forKey: lastLayoutKey)
        }
        
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: binary)
        proc.arguments = ["--layout", layout]
        
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = pipe
        
        proc.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.process = nil
                self?.notifyStatusChange(running: false)
            }
        }
        
        do {
            try proc.run()
            process = proc
            print("Process started with PID: \(proc.processIdentifier)")
            notifyStatusChange(running: true)
            monitorOutput(pipe: pipe)
        } catch {
            showAlert("Failed to start: \(error.localizedDescription)")
            print("Error starting process: \(error)")
        }
    }
    
    func stop() {
        guard let proc = process else { return }
        
        let pid = proc.processIdentifier
        
        if proc.isRunning {
            // Try graceful termination
            proc.terminate()
            
            // Wait briefly for graceful shutdown
            usleep(200_000) // 200ms
            
            // Force kill if still running
            if proc.isRunning {
                kill(pid, SIGKILL)
                usleep(100_000) // 100ms to ensure it's dead
            }
        }
        
        process = nil
        notifyStatusChange(running: false)
    }
    
    func restart() {
        stop()
        // Small delay to ensure cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.start()
        }
    }
    
    deinit {
        stop()
    }
    
    func togglePause() {
        guard let proc = process, proc.isRunning else { return }
        sendF10Event()
    }
    
    private func getBinaryPath() -> String? {
        return userDefaults.string(forKey: binaryPathKey) ?? bundledBinaryPath()
    }
    
    private func getLayoutPath() -> String? {
        if let saved = userDefaults.string(forKey: lastLayoutKey) {
            return saved
        }
        return LayoutManager.firstAvailableLayout(layoutsDir: LayoutManager.getLayoutsDir())
    }
    
    private func bundledBinaryPath() -> String? {
        return Bundle.main.url(forResource: "OpenLipi", withExtension: nil, subdirectory: "bin")?.path
    }
    
    private func monitorOutput(pipe: Pipe) {
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if data.isEmpty { return }
            
            if let output = String(data: data, encoding: .utf8) {
                self?.parseOutput(output)
            }
        }
    }
    
    private func parseOutput(_ output: String) {
        for line in output.split(separator: "\n") {
            if line.contains("Lipi Mapping:") {
                let isOn = line.contains("ON")
                DispatchQueue.main.async { [weak self] in
                    self?.isMappingEnabled = isOn
                    self?.notifyStatusChange(running: self?.process?.isRunning ?? false)
                }
            }
        }
    }
    
    private func sendF10Event() {
        let keyCode = CGKeyCode(kVK_F10)
        if let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true) {
            keyDown.post(tap: .cghidEventTap)
        }
        if let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) {
            keyUp.post(tap: .cghidEventTap)
        }
    }
    
    private func notifyStatusChange(running: Bool) {
        onStatusChange?(running, isMappingEnabled)
    }
    
    private func showAlert(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "OpenLipi"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

// MARK: - Layout Manager
class LayoutManager {
    var layoutsMenu: NSMenu?
    var onBinaryChanged: (() -> Void)?
    var onLayoutsFolderChanged: (() -> Void)?
    var onLayoutChanged: (() -> Void)?
    
    private let userDefaults = UserDefaults.standard
    private let layoutsDirKey = "openlipi.layoutsDir"
    private let lastLayoutKey = "openlipi.lastLayout"
    
    func refreshLayoutsMenu() {
        guard let menu = layoutsMenu else { return }
        menu.removeAllItems()
        
        guard let dir = Self.getLayoutsDir() else {
            let item = NSMenuItem(title: "Set layouts folder…", action: #selector(selectLayoutsFolderMenuItem(_:)), keyEquivalent: "")
            item.target = self
            menu.addItem(item)
            return
        }
        
        let selectedLayout = userDefaults.string(forKey: lastLayoutKey)
        let fm = FileManager.default
        
        guard let languages = try? fm.contentsOfDirectory(atPath: dir) else {
            menu.addItem(withTitle: "No layouts found", action: nil, keyEquivalent: "")
            return
        }
        
        for lang in languages.sorted() {
            let langPath = (dir as NSString).appendingPathComponent(lang)
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: langPath, isDirectory: &isDir), isDir.boolValue else { continue }
            
            addLanguageMenu(lang: lang, langPath: langPath, selectedLayout: selectedLayout, to: menu)
        }
        
        if menu.items.isEmpty {
            menu.addItem(withTitle: "No layouts found", action: nil, keyEquivalent: "")
        }
    }
    
    private func addLanguageMenu(lang: String, langPath: String, selectedLayout: String?, to menu: NSMenu) {
        let submenu = NSMenu(title: lang)
        let fm = FileManager.default
        
        if let files = try? fm.contentsOfDirectory(atPath: langPath) {
            for file in files.sorted() where file.hasSuffix(".json") {
                let name = file.replacingOccurrences(of: ".json", with: "")
                let item = NSMenuItem(title: name, action: #selector(selectLayout(_:)), keyEquivalent: "")
                item.target = self
                let fullPath = (langPath as NSString).appendingPathComponent(file)
                item.representedObject = fullPath
                
                if fullPath == selectedLayout {
                    item.state = .on
                }
                submenu.addItem(item)
            }
        }
        
        if submenu.items.isEmpty {
            submenu.addItem(withTitle: "(empty)", action: nil, keyEquivalent: "")
        }
        
        let langItem = NSMenuItem(title: lang, action: nil, keyEquivalent: "")
        langItem.submenu = submenu
        menu.addItem(langItem)
    }
    
    func selectBinary() {
        let panel = NSOpenPanel()
        panel.title = "Select OpenLipi Binary"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.begin { response in
            if response == .OK, let url = panel.url {
                self.userDefaults.set(url.path, forKey: "openlipi.binaryPath")
                self.onBinaryChanged?()
            }
        }
    }
    
    func selectLayoutsFolder(completion: (() -> Void)? = nil) {
        let panel = NSOpenPanel()
        panel.title = "Select Layouts Folder"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.begin { response in
            if response == .OK, let url = panel.url {
                self.userDefaults.set(url.path, forKey: self.layoutsDirKey)
                // Clear last layout since the folder changed
                self.userDefaults.removeObject(forKey: self.lastLayoutKey)
                self.onLayoutsFolderChanged?()
                completion?()
            }
        }
    }
    
    @objc private func selectLayoutsFolderMenuItem(_ sender: Any) {
        selectLayoutsFolder { [weak self] in
            self?.refreshLayoutsMenu()
        }
    }
    
    @objc private func selectLayout(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else { return }
        userDefaults.set(path, forKey: lastLayoutKey)
        refreshLayoutsMenu()
        onLayoutChanged?()
    }
    
    static func getLayoutsDir() -> String? {
        let defaults = UserDefaults.standard
        return defaults.string(forKey: "openlipi.layoutsDir") ?? bundledLayoutsDir()
    }
    
    private static func bundledLayoutsDir() -> String? {
        return Bundle.main.url(forResource: "layouts", withExtension: nil)?.path
    }
    
    static func firstAvailableLayout(layoutsDir: String?) -> String? {
        guard let dir = layoutsDir else { return nil }
        let fm = FileManager.default
        guard let langs = try? fm.contentsOfDirectory(atPath: dir) else { return nil }
        
        for lang in langs.sorted() {
            let langPath = (dir as NSString).appendingPathComponent(lang)
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: langPath, isDirectory: &isDir), isDir.boolValue else { continue }
            
            if let files = try? fm.contentsOfDirectory(atPath: langPath),
               let file = files.sorted().first(where: { $0.hasSuffix(".json") }) {
                return (langPath as NSString).appendingPathComponent(file)
            }
        }
        return nil
    }
}

// MARK: - Status Bar Manager
class StatusBarManager {
    private let statusItem: NSStatusItem
    
    init(statusItem: NSStatusItem) {
        self.statusItem = statusItem
    }
    
    func updateStatus(running: Bool, enabled: Bool) {
        guard let button = statusItem.button else { return }
        
        if let icon = loadIcon(enabled: running && enabled) {
            button.image = icon
            button.title = ""
            button.attributedTitle = NSAttributedString(string: "")
        } else {
            // Fallback to text-based status
            updateWithTextStatus(button: button, running: running, enabled: enabled)
        }
        
        let mappingText = enabled ? "ON" : "OFF"
        button.toolTip = running ? "OpenLipi (\(mappingText))" : "OpenLipi (Stopped)"
    }
    
    private func updateWithTextStatus(button: NSStatusBarButton, running: Bool, enabled: Bool) {
        let dotColor: NSColor = (running && enabled) ? .systemGreen : .systemGray
        let baseFont = NSFont.systemFont(ofSize: NSFont.systemFontSize + 5)
        
        let title = NSMutableAttributedString(
            string: "ఱ",
            attributes: [
                .font: baseFont,
                .foregroundColor: NSColor.labelColor
            ]
        )
        
        let attachment = createStatusDotAttachment(color: dotColor)
        title.append(NSAttributedString(attachment: attachment))
        
        button.attributedTitle = title
        button.image = nil
    }
    
    private func loadIcon(enabled: Bool) -> NSImage? {
        let appearance = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua])
        let isDark = (appearance == .darkAqua)
        
        let iconName: String
        if enabled {
            iconName = isDark ? "icon_on_dark" : "icon_on_light"
        } else {
            iconName = isDark ? "icon_off_dark" : "icon_off_light"
        }
        
        guard let url = Bundle.main.url(forResource: iconName, withExtension: "png") else {
            return nil
        }
        return NSImage(contentsOf: url)
    }
    
    private func createStatusDotAttachment(color: NSColor) -> NSTextAttachment {
        let size: CGFloat = 5.0
        let dotImage = NSImage(size: NSSize(width: size, height: size))
        dotImage.lockFocus()
        color.setFill()
        NSBezierPath(ovalIn: NSRect(x: 0, y: 0, width: size, height: size)).fill()
        dotImage.unlockFocus()
        
        let attachment = NSTextAttachment()
        attachment.image = dotImage
        attachment.bounds = NSRect(x: 5, y: -2, width: size, height: size)
        return attachment
    }
}
