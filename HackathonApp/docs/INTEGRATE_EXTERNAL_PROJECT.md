# Integrating a Separate Single-Screen Project into HackathonApp

This guide explains how to bring a single-screen app from another Xcode/Swift project into HackathonApp.

## 1. Copy your files into this app

Your project uses **folder sync** (Xcode’s `PBXFileSystemSynchronizedRootGroup`), so any file you add under `HackathonApp/HackathonApp/` is picked up automatically—no need to add files in the project navigator by hand.

**Suggested layout:**

- **Your main screen**  
  Copy the SwiftUI view file(s) into:
  - `HackathonApp/Views/`  
  or a dedicated folder, e.g. `HackathonApp/Views/MyFeature/`.

- **Models / services / utilities**  
  Copy into:
  - `HackathonApp/Models/`
  - `HackathonApp/Services/`
  - `HackathonApp/Utilities/`  
  (or a subfolder like `HackathonApp/MyFeature/` if you want everything in one place.)

- **Assets**  
  Copy images/colors into `HackathonApp/Assets.xcassets/` (or add a new `.xcassets` in the same folder and it will sync).

## 2. Add your screen as a tab

In `HackathonAppApp.swift`, the app uses a `TabView`. To show your screen:

- **If your view is named `MyScreenView`** (or similar):  
  Add a new tab that presents that view, e.g.:

  ```swift
  TabView {
      DashboardView()
          .tabItem { Label("Dashboard", systemImage: "house.fill") }
      MyScreenView()  // your integrated screen
          .tabItem { Label("My Feature", systemImage: "star.fill") }
  }
  ```

- **If you use the placeholder:**  
  There is a stub `IntegratedScreenView` in `Views/IntegratedScreenView.swift`. Either:
  - Replace the contents of that file with your screen’s code and keep the same struct name, or  
  - Rename your view to `IntegratedScreenView` and paste it there, or  
  - Add a new tab that uses your view’s real name and remove/ignore the placeholder.

## 3. Fix naming and type conflicts

- **Duplicate type names**  
  If both projects define the same type (e.g. `CognitiveScore`, `Item`), you have two options:
  - Use the existing type in HackathonApp and delete the duplicate from your copied code, or  
  - Rename your type (e.g. `MyCognitiveScore`) and update all references in your copied files.

- **SwiftData / Core Data**  
  If your screen uses SwiftData, add your model types to the `Schema` in `HackathonAppApp.swift` (`sharedModelContainer`) so they are part of the same container. If you use a different persistence layer, keep that code and any needed setup in your view or a dedicated service.

## 4. Dependencies (Swift Package Manager)

If your other project uses Swift packages:

1. In Xcode: **File → Add Package Dependencies…**
2. Add the same package URLs (and versions) you used in the other project.
3. Add the required products to the **HackathonApp** target.

Your copied code will then see those packages in this app.

## 5. Quick checklist

- [ ] Copy view + any models/services/utilities into `HackathonApp/HackathonApp/` (e.g. under `Views/`, `Models/`, `Services/`).
- [ ] Resolve duplicate type names (use existing or rename).
- [ ] Add your view as a tab in `HackathonAppApp.swift` (or replace `IntegratedScreenView`).
- [ ] Add any Swift packages via **File → Add Package Dependencies…**.
- [ ] If you use SwiftData, register new model types in `sharedModelContainer` in `HackathonAppApp.swift`.
- [ ] Build and run; fix any missing imports or target membership (everything under the synced `HackathonApp` folder is in the target by default).

Once your screen file is in place and wired in the `TabView`, it will appear as a second tab in the app.
