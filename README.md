# LocalTrade Marketplace

LocalTrade is a modern social commerce platform that connects local sellers and farmers with restaurants. The app delivers an Instagram-style experience with role-based workflows, real-time-inspired messaging, orders tracking, and a polished Material Design 3 interface.

## Feature Highlights

- Role-based flows for Sellers/Farmers and Restaurants
- Instagram-like feed with stories, filters, and immersive post cards
- Mock real-time messaging UI with chat management and unread badges
- Order lifecycle management with status tabs and actionable cards
- Location-aware search with filters, categories, and saved queries
- Polished UI/UX with animations, haptic feedback, and responsive layouts

## Tech Stack

- Flutter (>=3.5.0) with Material Design 3
- Riverpod for state management
- go_router for declarative navigation and auth guards
- Google Fonts, CachedNetworkImage, Shimmer, Flutter Animate, and other UI utilities

## Architecture

The project follows a feature-first structure inspired by clean architecture principles:

- `lib/app`: Application shell, router, and global providers
- `lib/core`: Themes, constants, utilities, and shared widgets
- `lib/features`: Feature modules (auth, home, search, create, messages, orders, profile, notifications, settings)

Each feature keeps its models, datasources, providers, presentation widgets, and screens grouped to encourage modularity and testability.

## Getting Started

1. Install Flutter SDK >= 3.5.0
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── app/
├── core/
└── features/
assets/
├── images/
└── animations/
```

- `lib/core/theme`: App-wide theming, color palettes, typography
- `lib/core/utils`: Validators, formatters, helpers (location, images)
- `lib/core/widgets`: Reusable UI components (buttons, text fields, shells)
- `lib/features/*`: Feature-first modules with data, domain, and presentation layers

## Mock Data & Offline Mode

LocalTrade currently operates as a frontend-only application with mock datasources. Datasources simulate latency and CRUD operations for posts, users, chats, orders, and notifications to mimic realistic scenarios without a live backend.

## Development Notes

- Use hot reload/hot restart to iterate quickly on UI changes
- Riverpod providers keep business logic testable and isolated
- go_router guards and shell routes provide scalable navigation
- Utilize Flutter DevTools for performance profiling and widget inspection
- Enable verbose logging via `flutter run -v` when debugging platform issues

## Future Enhancements

- Replace mock datasources with real backend services (REST/GraphQL)
- Integrate Firebase/Firestore or a custom backend for real-time messaging
- Add secure authentication, payment gateway integration, and push notifications
- Expand analytics, A/B testing, and internationalization support

LocalTrade lays the groundwork for a production-ready social commerce experience tailored to local trade ecosystems. Contributions and improvements are welcome!

