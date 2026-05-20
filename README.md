# Multi-Screen Flutter Application

A multi-screen Flutter application featuring user authentication, comprehensive
form validation, session persistence, navigation, and **full REST CRUD against
a live API** — built using clean architecture principles with a clear
separation between UI and business logic.

**Repository:** [github.com/Haris357/flutter-multi-screen-app](https://github.com/Haris357/flutter-multi-screen-app)

**Current feature branch:** `feature/course-api-integration`

## Student Information

| Field        | Detail                               |
|--------------|--------------------------------------|
| Student Name | Haris                                |
| Student ID   | Se231097                             |
| Project      | Multi-Screen Application Development  |

## API Used

This branch integrates **[JSONPlaceholder](https://jsonplaceholder.typicode.com/)**,
a free fake REST API used for prototyping and learning. The `/posts` endpoint is
treated as the "courses" resource with the following field mapping:

| Course field | JSONPlaceholder `/posts` field |
|--------------|--------------------------------|
| `id`         | `id`                           |
| `title`      | `title`                        |
| `description`| `body`                         |
| `userId`     | `userId` (defaults to `1`)     |

### Endpoints exercised

| Operation | Method | URL                                                |
|-----------|--------|----------------------------------------------------|
| Read all  | GET    | `https://jsonplaceholder.typicode.com/posts`       |
| Read one  | GET    | `https://jsonplaceholder.typicode.com/posts/{id}`  |
| Create    | POST   | `https://jsonplaceholder.typicode.com/posts`       |
| Update    | PUT    | `https://jsonplaceholder.typicode.com/posts/{id}`  |
| Delete    | DELETE | `https://jsonplaceholder.typicode.com/posts/{id}`  |

> JSONPlaceholder is a **fake** API: POSTs always return `id: 101`, and
> updates / deletes are echoed but not actually persisted server-side. The app
> mirrors the response into local controller state so the UI updates as if the
> change persisted.

### Documentation followed

The official guide was used as the reference for endpoint behaviour and
expected request/response shapes:

- **Guide:** <https://jsonplaceholder.typicode.com/guide>
- **Resources:** <https://jsonplaceholder.typicode.com/>

## Screenshots

| Registration | Login |
|--------------|-------|
| ![Registration](screenshots/Registration.png) | ![Login](screenshots/Login.png) |

| Dashboard (with live courses preview) | Courses list (CRUD) |
|---------------------------------------|---------------------|
| ![Dashboard](screenshots/Dashboard.png) | ![Courses](screenshots/Courses.png) |

| Add / Edit course | Course detail |
|-------------------|---------------|
| ![Course form](screenshots/CourseForm.png) | ![Course detail](screenshots/CourseDetail.png) |

> The `Courses.png`, `CourseForm.png` and `CourseDetail.png` screenshots are
> captured from the screens introduced on the `feature/course-api-integration`
> branch and live in the `screenshots/` folder alongside the originals.

## Features

### 1. Registration Screen

- First name, last name, email, gender (dropdown) and password fields.
- Password security rules: minimum 6 characters, at least 1 uppercase letter
  and at least 1 special character.
- Confirm-password field that must match the original password.
- Real-time validation feedback on every field.
- Submit button stays **disabled** until the whole form is valid.
- On success: shows a success message and navigates to the Login screen.

### 2. Login Screen

- Email field with format validation and inline error messages.
- Password field with a show/hide (eye icon) toggle.
- "Remember Me" checkbox that persists the session across app restarts.
- Validates credentials; on success navigates to the Dashboard, passing the
  user data.

### 3. Dashboard Screen

- Displays the user's name, email and an avatar placeholder (initials).
- Live "Your Courses" preview pulled from the JSONPlaceholder API, with
  loading, error and empty states.
- Buttons to open the full Courses screen ("View all") and to jump straight
  into adding a new course.
- Logout button (with confirmation) returns to the Login screen.

### 4. Courses Screen (CRUD)

A dedicated screen for the full Create / Read / Update / Delete flow:

- **Read (GET)** — fetches the course list on first open, shows a
  `CircularProgressIndicator` while loading and an error view with a retry
  button on failure. Supports pull-to-refresh and a refresh action in the
  app bar.
- **Create (POST)** — floating "Add course" button opens a form. On success
  the new course is prepended to the list and a confirmation snack-bar
  appears.
- **Update (PUT)** — each course card has an Edit action that opens the same
  form pre-filled with existing data. Saving sends a PUT and updates the UI.
- **Delete (DELETE)** — each course card has a Delete action that opens a
  confirmation dialog. On confirm, the API call is fired and the course is
  removed from the list.

### 5. Course Detail Screen

- Banner with the course id.
- Course title, id and full description.
- Edit shortcut in the app bar.
- Falls back to a single `GET /posts/{id}` request if the course is not
  already cached in the controller.

## Architecture

The project separates UI from business logic into dedicated layers:

```text
lib/
├── main.dart                          App entry + AuthScope + CourseScope wiring
├── enums/
│   └── app_enums.dart                 Gender, AuthState, AuthStatus enums
├── models/
│   ├── user_model.dart                Immutable user model (+ JSON serialization)
│   └── course_model.dart              Immutable course model (+ JSON serialization)
├── validators/
│   └── validators.dart                Reusable, UI-independent validation logic
├── services/
│   ├── session_service.dart           SharedPreferences-backed session storage
│   └── course_api_service.dart        HTTP service for /posts (GET/POST/PUT/DELETE)
├── controllers/
│   ├── auth_controller.dart           Authentication business logic
│   ├── auth_scope.dart                InheritedNotifier exposing AuthController
│   ├── course_controller.dart         Course CRUD + loading/error/data state
│   ├── course_scope.dart              InheritedNotifier exposing CourseController
│   └── navigation_controller.dart     Route names + navigation helpers
├── screens/
│   ├── registration_screen.dart
│   ├── login_screen.dart
│   ├── dashboard_screen.dart
│   ├── courses_screen.dart            CRUD list view
│   ├── course_form_screen.dart        Shared create + edit form
│   └── course_detail_screen.dart      Single-course read view
└── widgets/
    ├── app_text_field.dart            Reusable validated text field
    └── primary_button.dart            Reusable button with loading/disabled state
```

### Key design points

- **Dedicated service layer** — All HTTP calls live in
  `CourseApiService`. It owns the base URL, the `http.Client`, request
  timeouts, JSON encoding/decoding and translates non-2xx responses into a
  typed `CourseApiException`. No widget or controller imports
  `package:http` directly.
- **State management** — `CourseController` extends `ChangeNotifier` and
  exposes a `CourseLoadState` enum (`idle`, `loading`, `loaded`, `error`)
  alongside the courses list and an error message. UI screens listen via
  `CourseScope` (an `InheritedNotifier`) and rebuild as state changes.
- **Loading / success / error handling** — the courses screen renders three
  distinct views based on `CourseLoadState`. Mutation methods on the
  controller (`addCourse`, `updateCourse`, `deleteCourse`) return `null` on
  success or a user-facing error string on failure, which the calling screen
  shows via a `SnackBar`.
- **Custom Validator class** — `Validators` holds all email, password, empty
  field, name, confirm-password and selection validation. It is pure logic
  with no UI dependency and is unit-tested.
- **Enums** — `Gender` (dropdown values), `AuthState` (authentication state),
  `AuthStatus` (auth operation results) and `CourseLoadState` (API view state).
- **Controller / navigation layer** — `AuthController` owns registration,
  login and logout; `SessionService` handles persistence;
  `NavigationController` centralises routing. Screens contain only UI and
  delegate to these classes.
- **Reusable components** — `AppTextField` and `PrimaryButton` standardise
  form inputs and actions across all screens, including the new course form.
- **Session persistence** — "Remember Me" stores the session via
  `shared_preferences`, so a remembered user is taken straight to the
  Dashboard on the next app launch.

## Getting Started

### Prerequisites

- Flutter SDK 3.41+ (Dart 3.11+)
- An internet connection (required to reach JSONPlaceholder)

### Run the app

```bash
git checkout feature/course-api-integration
flutter pub get
flutter run
```

To run in a browser instead (no Windows setup required):

```bash
flutter run -d chrome
```

### Run the tests

```bash
flutter test
```

The test suite covers the `Validators` class (email, password,
confirm-password and required-field rules) — 11 tests, all passing.

## Usage

1. Launch the app; the Login screen appears.
2. Tap **Register** and complete the registration form.
3. After successful registration you are returned to the Login screen.
4. Log in with the **same email and password** you just registered.
5. The Dashboard loads a live preview of courses from JSONPlaceholder.
6. Tap **View all** (or **Add course**) to open the CRUD screen, where you
   can list, create, edit and delete courses against the live API.

## Tech Stack

- **Flutter** (Material 3)
- **Dart**
- **http** — REST calls to JSONPlaceholder
- **shared_preferences** — local session persistence
- **JSONPlaceholder** — fake REST backend for course CRUD
  ([guide](https://jsonplaceholder.typicode.com/guide))

## Submission

- **Branch:** `feature/course-api-integration`
- **API:** JSONPlaceholder (`/posts` → courses)
- **Documentation followed:** <https://jsonplaceholder.typicode.com/guide>
