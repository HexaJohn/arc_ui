import Cocoa
import FlutterMacOS
import SwiftUI

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    SystemPreferencesChannel.register(with: flutterViewController)
    NativeSidebarFactory.register(with: flutterViewController)

    super.awakeFromNib()
  }
}

/// Reads the macOS preferences arc_ui honours but cannot read itself.
///
/// They live in `NSUserDefaults` under the global domain, and arc_ui is a pure
/// Dart package with no native side. Shelling out to `defaults` is not an
/// alternative either — this app runs under the App Sandbox, which blocks it.
/// Reading the global domain from within the sandbox *is* permitted, so a few
/// lines here are all it takes; the values are then handed to
/// `ArcSystemPreferences` on the Dart side.
///
/// Lives in this file rather than its own so that adding it needs no change to
/// `project.pbxproj`.
enum SystemPreferencesChannel {
  private static let channelName = "arc_ui/system_preferences"

  static func register(with controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: controller.engine.binaryMessenger
    )

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "read":
        result(current())
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let push = { channel.invokeMethod("changed", arguments: current()) }

    // Two triggers, because neither alone is sufficient. didChangeNotification
    // is not reliably delivered for edits made by *another* process, which is
    // exactly what System Settings is; re-reading on activation catches the
    // common case of the user changing a setting and switching back.
    NotificationCenter.default.addObserver(
      forName: UserDefaults.didChangeNotification,
      object: nil,
      queue: .main
    ) { _ in push() }

    NotificationCenter.default.addObserver(
      forName: NSApplication.didBecomeActiveNotification,
      object: nil,
      queue: .main
    ) { _ in push() }
  }

  private static func current() -> [String: Any] {
    let defaults = UserDefaults.standard

    // 1 small, 2 medium, 3 large. Absent means medium, so `integer(forKey:)`
    // is not usable here — it returns 0 for a missing key.
    let sidebarIconSize = defaults.object(forKey: "NSTableViewDefaultSizeMode") as? Int ?? 2

    // "Automatic" | "WhenScrolling" | "Always". Absent means Automatic.
    let showScrollBars = defaults.string(forKey: "AppleShowScrollBars") ?? "Automatic"

    // true means "jump to the spot that's clicked".
    let scrollerPagingToSpot = defaults.bool(forKey: "AppleScrollerPagingBehavior")

    return [
      "sidebarIconSize": sidebarIconSize,
      "showScrollBars": showScrollBars,
      "scrollerPagingToSpot": scrollerPagingToSpot,
    ]
  }
}


// MARK: - Hosting a native view inside Flutter

/// A real SwiftUI `NavigationSplitView`, embedded in the Flutter tree.
///
/// Serves two purposes: it is the worked example of hosting a native view, and
/// it gives the arc_ui macOS sidebar something authoritative to sit beside —
/// AppKit drawing the real thing rather than an approximation of it.
///
/// `Section(_:isExpanded:)` needs macOS 14 and `NavigationSplitView` needs 13,
/// while this app deploys to 10.15, so the whole view is gated and a plain
/// message stands in on older systems.
@available(macOS 14.0, *)
enum Panel: Hashable {
  case inbox, drafts, sent
  case project(String)
}

@available(macOS 14.0, *)
struct NativeSidebarContent: View {
  @State private var selection: Panel? = .inbox
  @State private var projectsExpanded = true

  var body: some View {
    NavigationSplitView {
      List(selection: $selection) {
        Section("Mail") {
          Label("Inbox", systemImage: "tray")
            .tag(Panel.inbox)
          Label("Drafts", systemImage: "doc")
            .tag(Panel.drafts)
          Label("Sent", systemImage: "paperplane")
            .tag(Panel.sent)
        }

        Section("Projects", isExpanded: $projectsExpanded) {
          ForEach(["Apollo", "Borealis"], id: \.self) { name in
            Label(name, systemImage: "folder")
              .tag(Panel.project(name))
          }
        }
      }
      .listStyle(.sidebar)
      .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 300)
    } detail: {
      switch selection {
      case .inbox: Text("Inbox")
      case .drafts: Text("Drafts")
      case .sent: Text("Sent")
      case .project(let name): Text(name)
      case nil: Text("Select an item")
      }
    }
  }
}

/// Builds the `NSView` Flutter embeds.
///
/// macOS's factory protocol is simpler than iOS's: it returns an `NSView`
/// directly, with no `FlutterPlatformView` wrapper. `NSHostingView` is the
/// adapter, since SwiftUI cannot produce an `NSView` on its own.
class NativeSidebarFactory: NSObject, FlutterPlatformViewFactory {
  /// Must match `AppKitView(viewType:)` on the Dart side. A mismatch fails at
  /// runtime as a blank rectangle with no error, so it is declared once here.
  static let viewType = "arc_ui/native_sidebar"

  func create(withViewIdentifier viewId: Int64, arguments args: Any?) -> NSView {
    if #available(macOS 14.0, *) {
      // Unsized on purpose — Flutter sets the frame from the widget's
      // constraints after creation.
      return NSHostingView(rootView: NativeSidebarContent())
    }
    let label = NSTextField(labelWithString: "Needs macOS 14")
    label.alignment = .center
    return label
  }

  static func register(with controller: FlutterViewController) {
    let registrar = controller.registrar(forPlugin: viewType)
    registrar.register(NativeSidebarFactory(), withId: viewType)
  }
}
