# Kmart Staff Portal

Flutter app for Kmart store staff, covering two roles:

- **Packer** — dashboard of orders to pack, packing history
- **Delivery** — assigned deliveries, delivery history

Shared: login screen and profile screen.

## Requirements

- Flutter SDK 3.x (Dart >= 3.0)
- No third-party packages beyond `cupertino_icons` — nothing to fetch beyond the SDK.

## Getting started

This archive contains only `pubspec.yaml` and the `lib/` sources. Generate the
platform folders (android/ios/web) the first time:

```bash
cd kmart_staff_portal
flutter create --project-name kmart_staff_portal .
flutter pub get
flutter run
```

`flutter create .` on an existing folder adds the missing platform scaffolding
and leaves `lib/` and `pubspec.yaml` untouched.

## Demo login

Any valid-looking email and a password of 4+ characters will log you in.
Use the **Login as Packer / Login as Delivery** toggle above the button to pick
which dashboard you land on — that toggle is a stand-in for a real auth
response and should be removed once the role comes back from your API.

## Project layout

```
lib/
├── main.dart                     App entry + theme wiring
├── theme/app_theme.dart          Colours, spacing, ThemeData
├── models/models.dart            StaffUser, PackerOrder, DeliveryOrder, enums
├── data/mock_data.dart           Static demo data — replace with API calls
├── widgets/common_widgets.dart   Logo, avatar, chips, stat tiles, ₹ formatting
└── screens/
    ├── login_screen.dart
    ├── home_shell.dart           Bottom nav, swaps pages per role
    ├── packer_dashboard_screen.dart
    ├── packer_history_screen.dart
    ├── delivery_dashboard_screen.dart
    ├── delivery_history_screen.dart
    └── profile_screen.dart
```

## Branding

| Token      | Value     |
|------------|-----------|
| Primary    | `#D32F2F` |
| Navy       | `#16265A` |
| Background | `#F9F9F9` |

## Known gaps before production

1. **Product images** are coloured letter tiles (`ProductThumb`) so the project
   builds with zero assets. Swap for `Image.asset` / `Image.network`.
2. **State is per-screen.** Marking an order packed does not move it into the
   History list. Lift the order lists into a shared store (Provider, Riverpod,
   or a plain `ChangeNotifier`) before real use.
3. **Phone numbers are not tappable.** Add `url_launcher` and a `tel:` link.
4. Summary figures follow the supplied design (5 Orders to Pack, 12 Items
   Today); the orders count is computed from the live list.
