# ExpenseOCR 🧾⚡

> **Intelligent, Offline-First Personal Finance & Receipt Scanner Mobile App**  
> Built with Flutter 3.x / Dart 3, On-Device AI (Google ML Kit), Local SQLite, and Pure `CustomPainter` Animated Canvas Visualizations.

---

## 🌟 Architecture & Highlights

- **Offline-First & Privacy-Preserving**: All OCR processing runs 100% on-device (sub-100ms extraction) using Google ML Kit and regex heuristics—no network required.
- **Custom Regex Heuristic Engine**:
  - **Monetary Totals**: Multi-tier bottom-up keyword hierarchy parsing Vietnamese (`150.000 đ`, `194.400 VND`, `TỔNG CỘNG`) and international (`$45.50`, `TOTAL DUE`) currencies while strictly ignoring cash tendered, change returned, and discount lines.
  - **Transaction Dates**: Robust extraction supporting `DD/MM/YYYY`, `DD-MM-YYYY`, `DD.MM.YYYY`, `YYYY-MM-DD`, and Vietnamese prose (`Ngày 15 tháng 10 năm 2026`).
  - **Merchant Brand Heuristics**: Automatic store detection (WinMart, Highlands Coffee, Fahasa, Circle K, Grab, CGV, etc.) with automatic noise filtering (headers, tax IDs, phone numbers).
  - **Category Auto-Inference**: Semantic classification into **Food**, **Study**, **Travel**, **Gear**, and **Entertainment**.
- **Pure `CustomPainter` Visualizations (Zero External Chart Libraries)**:
  - **Animated Category Donut Chart**: Proportional slice angles calculated from category totals, outer highlight stroke on tap, central interactive metric badge, and custom legend.
  - **Weekly Spending Bar Chart**: Animated bar rise from 0, horizontal dotted grid lines, Y-axis currency scale, and floating interactive tooltip on tap.
- **Persistent Local Database**: Cross-platform SQLite engine with automatic schema migrations and desktop FFI support.
- **Clean Architecture / Feature-First Directory Structure**:
  ```text
  lib/
  ├── app/
  │   ├── constants/       # App colors, thresholds, database constants
  │   ├── routes/          # Typed routing and navigation arguments
  │   └── theme/           # Material 3 light and dark themes
  ├── core/
  │   ├── database/        # SQLite singleton & ExpenseDao
  │   ├── services/        # OCR service, image picker, secure file storage
  │   └── utils/           # Regex heuristics engine, date & currency formatters
  ├── features/
  │   ├── camera/          # Viewfinder overlay with animated laser line & controls
  │   ├── expense/         # Models, repository, Provider state management
  │   ├── review/          # Pre-filled interactive review & validation screen
  │   ├── dashboard/       # Spending summary card, category filter chips, search
  │   └── analytics/       # Pure CustomPainter Donut and Weekly Bar charts
  └── main.dart
  ```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `^3.x`
- Dart SDK `^3.x`

### Running the App
```bash
# Get dependencies
flutter pub get

# Run on connected device or simulator
flutter run
```

### Running Tests
The project includes comprehensive unit and widget tests covering Regex Heuristics, Currency Formatting, Date Formatting, SQLite Model Serialization, and CustomPainter Charts:
```bash
flutter test
```

### Static Analysis
Verify that the codebase has 0 lint errors or warnings:
```bash
flutter analyze
```

---

## 📸 Key Workflows

1. **Scan Receipt**: Tap "Scan Receipt" to launch the camera viewfinder with the animated laser framing guide, or pick an existing receipt from the gallery. (On desktop/simulators, tap the receipt icon to select realistic preset receipts like WinMart+, Highlands Coffee, Fahasa Bookstore, Circle K, or Grab).
2. **Review & Edit**: AI-extracted fields are pre-populated with an extraction confidence score. Tap the receipt thumbnail to zoom in using `InteractiveViewer`, adjust values if needed, and commit to local storage.
3. **Dashboard & Analytics**: Filter transactions by category or search term, view real-time monthly totals, and tap "Analytics" to inspect animated CustomPainter Donut and Weekly Bar charts.
