# SmartPhotoSearch 📸

A production-quality iOS photo management app built with SwiftUI and Firebase. SmartPhotoSearch allows users to browse, upload, and search their photo library with an intelligent, scalable architecture designed to FAANG engineering standards.

---

## Demo

| Grid View | Pinch to Zoom | Photo Detail | Upload Progress |
|-----------|---------------|--------------|-----------------|
| 3-column lazy grid | 1-6 columns dynamically | Full screen with zoom | Per-cell progress bar |

---

## Features

### Current (Milestone 1)
- 📷 **Photo Library Browsing** — Lazy-loading grid with smooth scrolling
- 🔍 **Pinch to Zoom Grid** — Dynamically resize from 1 to 6 columns
- 🖼️ **Photo Detail View** — Full screen with pinch to zoom (1x–5x), drag to pan, double tap to reset
- ☁️ **Firebase Upload Pipeline** — Upload photos to Firebase Storage with real-time progress
- ✅ **Upload State Tracking** — Per-cell visual states (uploading, done, failed)
- 🔲 **Multi-Select Mode** — Long press to enter selection mode, tap to select individual photos
- 🔄 **Upload State Persistence** — Syncs upload status from Firestore on launch
- 🔐 **Permission Handling** — Graceful handling of all PHAuthorizationStatus cases
- 📦 **Limited Permission Flow** — Banner + expand picker for limited photo access

### Coming Soon
- 🏷️ **Auto-Tagging** — On-device object detection via Vision framework (Milestone 2)
- 🔎 **Natural Language Search** — Search photos by content (Milestone 3)
- 👤 **Face Clustering** — Automatic people albums via face embeddings (Milestone 4)
- 📅 **Timeline Browsing** — Browse by year, month, day (Milestone 5)

---

## Architecture

SmartPhotoSearch follows **Clean Architecture** with strict separation of concerns. Every layer is protocol-driven for testability.

```
┌─────────────────────────────────────┐
│              Views                  │
│  ContentView, GalleryGrid,          │
│  PhotoDetailView, LazyImageCell     │
├─────────────────────────────────────┤
│            ViewModels               │
│  GalleryViewModel (@MainActor)      │
├─────────────────────────────────────┤
│             Services                │
│  PhotoLibraryService                │
│  UploadService                      │
│  BackgroundUploadService            │
├─────────────────────────────────────┤
│              Utils                  │
│  LazyImageLoader                    │
│  ImageRequestStore (actor)          │
└─────────────────────────────────────┘
```

### Key Architectural Decisions

| Decision | Rationale |
|----------|-----------|
| Protocol-driven services | Every service has a protocol — fully mockable in tests |
| `@MainActor` on ViewModel | Guarantees UI updates on main thread |
| `actor` for image requests | Eliminates race conditions on `requestID` |
| `NSObject` + `PHPhotoLibraryChangeObserver` | Live photo library updates |
| Firebase observers for progress | Reliable upload progress tracking |
| `sanitize()` helper | Consistent assetID handling across upload pipeline |

---

## Tech Stack

| Category | Technology |
|----------|------------|
| UI Framework | SwiftUI |
| Language | Swift 5.9 |
| Storage | Firebase Storage |
| Database | Firebase Firestore |
| Photo Access | PhotoKit (PHAsset, PHImageManager) |
| On-device AI | Vision.framework (Milestone 2) |
| Concurrency | Swift Concurrency (async/await, actor, Task) |
| Testing | XCTest |
| Minimum iOS | iOS 15.0 |

---

## Project Structure

```
SmartPhotoSearch/
├── App/
│   ├── SmartPhotoSearchApp.swift    # App entry point
│   └── AppDelegate.swift            # Firebase init + background upload handler
│
├── Services/
│   ├── PhotoLibraryService.swift    # PHAsset fetching + permission requests
│   ├── PHPhotoLibraryProtocol.swift # Abstraction over Apple's static PHPhotoLibrary API
│   ├── LivePHPhotoLibrary.swift     # Real implementation of PHPhotoLibraryProtocol
│   ├── UploadService.swift          # Orchestrates image extraction + upload
│   └── BackgroundUploadService.swift# Firebase Storage upload + Firestore metadata
│
├── ViewModels/
│   └── GalleryViewModel.swift       # Drives all gallery UI state
│
├── Views/
│   ├── ContentView.swift            # Navigation shell
│   ├── GalleryGrid.swift            # Lazy grid + pinch gesture + navigation
│   ├── GalleryToolbar.swift         # Context-sensitive upload toolbar
│   ├── LazyImageCell.swift          # Individual photo cell with overlays
│   ├── PhotoDetailView.swift        # Full screen photo viewer with zoom
│   ├── LimitedAccessBanner.swift    # Limited permission UI
│   └── PermissionDeniedView.swift   # Denied permission UI
│
├── Utils/
│   ├── LazyImageLoader.swift        # ObservableObject driving image loading
│   └── ImageRequestStore.swift      # actor — thread-safe request tracking
│
├── Models/
│   └── UploadStatus.swift           # pending/uploading/done/failed
│
└── Extensions/
    ├── Comparable+Clamped.swift     # Grid column clamping
    ├── PHAsset+Hashable.swift       # NavigationLink compatibility
    └── LimitedPickerPresenter.swift # Safe UIKit bridge for limited picker
```

---

## Setup

### Prerequisites
- Xcode 15+
- iOS 15.0+ simulator or device
- Firebase account

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/SmartPhotoSearch.git
cd SmartPhotoSearch
```

2. **Firebase Setup**
   - Create a project at [console.firebase.google.com](https://console.firebase.google.com)
   - Add an iOS app with your bundle ID
   - Download `GoogleService-Info.plist` and add to the project
   - Enable **Firebase Storage** and **Firestore** in test mode
   - Upgrade to Blaze plan (required for Storage)

3. **Open in Xcode**
```bash
open SmartPhotoSearch.xcodeproj
```

4. **Run**
   - Select your simulator or device
   - Press `Cmd+R`

---

## Testing

```bash
# Run all unit tests
Cmd+U
```

### Test Coverage

```
SmartPhotoSearchTests/
├── Mocks/
│   ├── MockPhotoLibraryService.swift   # Controls permission + asset responses
│   └── MockPHPhotoLibrary.swift        # Controls PHPhotoLibrary authorization
├── GalleryViewModelTests.swift          # Permission state machine, asset loading
└── PhotoLibraryServiceTests.swift       # Authorization flow, main thread delivery
```

### Testing Philosophy

Every external dependency is hidden behind a protocol and replaced with a mock in tests:

```
Real code:   ViewModel → Protocol ← RealService (touches iOS APIs)
Tests:       ViewModel → Protocol ← MockService (returns controlled data)
```

---

## Engineering Standards

This project is built to FAANG engineering standards:

- ✅ **No retain cycles** — `[weak self]` throughout all closures
- ✅ **Thread safety** — `actor` for shared mutable state
- ✅ **Single responsibility** — every file has one job
- ✅ **Dependency injection** — no singletons in business logic
- ✅ **DRY** — no duplicated logic (e.g. `sanitize()` helper)
- ✅ **Testable** — protocol-driven, fully mockable
- ✅ **Memory safe** — `NSCache` with count and cost limits

---

## Roadmap

| Milestone | Status | Features |
|-----------|--------|---------|
| 1 — Trustworthy | ✅ Complete | Upload pipeline, permissions, grid |
| 2 — Smart | 🔄 In Progress | Auto-tagging via Vision framework |
| 3 — Searchable | ⬜ Planned | Natural language search |
| 4 — Personal | ⬜ Planned | Face clustering, people albums |
| 5 — Polished | ⬜ Planned | Timeline, shimmer, animations |

---

## Author

**Lâm Trần**
Built as a portfolio project targeting FAANG iOS engineering standards.

---

## License

MIT License — see [LICENSE](LICENSE) for details.
