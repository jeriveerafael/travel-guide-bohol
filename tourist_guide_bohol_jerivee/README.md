# Tourist Information and Travel Guide Mobile Website

A Flutter Web tourism guide for Bohol, Philippines, using **Dart + Flutter Web + PHP REST API + MySQL**. The backend is designed for local development with XAMPP. It does not require a third-party backend service.

## Included in this revised starter

- Responsive Flutter Web interface for desktop, tablet, and mobile browsers
- Sample Bohol destinations and categories
- Destination search and category filtering
- Destination detail view with entrance fees, operating hours, travel tips, contact information, activities, and accommodation guidance
- Interactive OpenStreetMap view and destination markers
- External directions links
- Favorites, saved destinations, and visited list in browser storage
- Recommended sample itineraries
- Real offline content cache in IndexedDB: destination catalogue, photos, and download timestamps
- Downloadable OpenStreetMap tiles for offline map viewing
- Cache-first map tiles with a global online/offline banner and automatic refresh
- Cached session support so a signed-in visitor can reopen the guide without the API
- Installable PWA with an offline app-shell service worker
- Self-contained phone user guide at `web/user-guide.html` (served at `/user-guide.html`) and a PDF at `web/Bohol-Explorer-Phone-Guide.pdf`, both downloadable for offline reading
- Optional browser geolocation for the visitor's own position
- PHP REST API for reading and managing destinations
- MySQL schema and sample destination records
- Password-hashed account registration and login API
- Expiring bearer-token sessions
- Administrator-only destination create, update, and delete endpoints
- Administrator dashboard with paginated user directory and user activity history
- Activity tracking for account registration/login/logout, destination searches/views, favorites, offline saves, visited destinations, saved itineraries, and admin destination changes
- Full-screen mandatory sign-in/sign-up page shown before the website
- Valid bearer-token session restoration for returning signed-in users
- Account menu with profile and sign-out
- Administrator dashboard visible only to admin-role accounts

## Technology stack

| Layer | Technology |
|---|---|
| Website | Flutter Web + Dart |
| IDE | Visual Studio Code |
| Backend | PHP 8.1+ REST API |
| Database | MySQL / MariaDB through PDO |
| Local development | XAMPP |
| HTTP requests | `http` Dart package |
| Map | Flutter Map + OpenStreetMap tiles |
| Browser preferences | Shared Preferences |

## 1. Requirements

- Flutter SDK compatible with the Dart SDK constraint in `pubspec.yaml`
- Visual Studio Code with Flutter and Dart extensions
- Google Chrome or Microsoft Edge
- XAMPP with Apache, MySQL, and PHP PDO MySQL enabled (PHP 8.1 or later)

Check the Flutter setup:

```bash
flutter doctor
flutter devices
flutter config --enable-web
```

## 2. Set up the MySQL database

1. Open the XAMPP Control Panel.
2. Start **Apache** and **MySQL**.
3. Open `http://localhost/phpmyadmin`.
4. Select **Import**.
5. Choose `backend/sql/database.sql` from this project.
6. Click **Import** / **Go**. The script creates the `bohol_tourism_db` database, its tables (including `activity_logs`), and sample destinations. It also updates the nine existing seed destinations on every import, so re-import this file to correct image URLs and coordinates in an older database.

If you already imported an earlier version and want to keep your existing records, import `backend/sql/admin_activity_upgrade.sql` once to add the `activity_logs` table, then import `backend/sql/destination_guide_upgrade.sql` once to add the contact, activities, and accommodation columns. Then import `backend/sql/database.sql` again to fill the new fields on the nine seed destinations; it updates matching IDs and leaves other records untouched. None of these scripts deletes users or destinations.

On a fresh installation, `database.sql` already includes every column. Do not run the upgrade scripts afterwards.

The default local database settings are in `backend/api/config.php`:

```php
const DB_HOST = '127.0.0.1';
const DB_NAME = 'bohol_tourism_db';
const DB_USER = 'root';
const DB_PASS = '';
```

Change these values if your MySQL installation uses a different username or password.

## 3. Install the PHP API in XAMPP

1. Open your XAMPP installation folder, usually `C:\xampp\htdocs\`.
2. Create a folder named `tourist_guide_bohol_api`.
3. Copy the contents of this project's `backend` folder into `C:\xampp\htdocs\tourist_guide_bohol_api\`.
4. Confirm that this file exists: `C:\xampp\htdocs\tourist_guide_bohol_api\api\index.php`.
5. Open this address in your browser:

```text
http://localhost/tourist_guide_bohol_api/api/index.php?resource=destinations
```

You should see JSON data containing the sample destination records. If you see a PHP error, check Apache's PHP error log and confirm that PDO MySQL is enabled.

## 4. Mandatory login and user registration

The website now uses a mandatory authentication gate. When there is no valid signed-in session, the first screen is the full-screen sign-in/sign-up page. The Home, Explore, Map, Saved, Itineraries, and Admin pages are not built or shown until the PHP API returns a valid user session. There is no guest-browsing or Continue as guest option.

1. Start Apache and MySQL in XAMPP and confirm the API URL in a browser.
2. Start the Flutter website. If there is no valid saved session, the sign-in/sign-up page appears first.
3. Select **Create account** to register with your name, email, and password (minimum 8 characters).
4. The new account is assigned the `user` role automatically and is signed in after successful registration.
5. Existing users enter their email and password and select **Sign in**.
6. Only after successful authentication does the website show the Home page and navigation.
7. Use the account menu to view the profile or sign out. Signing out returns the user to the full-screen sign-in page.

A valid bearer-token session is restored when the browser is reopened, so a returning authenticated user may go directly to the website. To return to the login page, use **Sign out**. If the token is expired or rejected by the API, the app clears it and shows the login page.

Passwords are hashed by PHP using `password_hash()`. The Flutter application never stores the plain-text password.

## 5. Create an administrator account

The registration endpoint creates regular accounts only. Promote your own account to administrator through phpMyAdmin after registering it.

In Windows PowerShell, run the following command (change the name and email):

```powershell
$body = @{
  fullName = "Website Administrator"
  email = "admin@example.com"
  password = "ChangeThisPassword123!"
} | ConvertTo-Json

Invoke-RestMethod `
  -Uri "http://localhost/tourist_guide_bohol_api/api/index.php?resource=auth&action=register" `
  -Method Post `
  -ContentType "application/json" `
  -Body $body
```

Then open phpMyAdmin, select `bohol_tourism_db`, open the SQL tab, and run this query with the email you registered:

```sql
UPDATE users
SET role = 'admin'
WHERE email = 'admin@example.com';
```

After changing the role, sign out of the website and sign in again so the updated administrator role is loaded. The **Admin dashboard** option will then appear in the account menu. Do not publish the sample password or share administrator credentials.

## 6. Run the Flutter Web website

Open the Flutter project folder (the folder containing `pubspec.yaml`) in VS Code. In the VS Code terminal run:

```bash
flutter pub get
flutter run -d chrome
```

The default API URL is:

```text
http://localhost/tourist_guide_bohol_api/api/index.php
```

To use a different API address, pass it when running Flutter:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost/tourist_guide_bohol_api/api/index.php
```

For a phone or another computer on the same network, `localhost` must be replaced with the development computer's LAN IP address, and Apache must be reachable from that device. Build and serve the release version for the phone:

```bash
flutter build web --release --dart-define=API_BASE_URL=http://192.168.1.25/tourist_guide_bohol_api/api/index.php
dart run tool/serve_web.dart 8123 --lan
```

Replace `192.168.1.25` with the computer's Wi-Fi IPv4 address. `--lan` makes the static server accept phone connections and prints the phone URL. Open the printed address on the phone. The full step-by-step phone instructions, offline-map walkthrough, troubleshooting, and demo checklist are in `web/user-guide.html` (open `/user-guide.html` on the served site and use its download button) and in `web/Bohol-Explorer-Phone-Guide.pdf`.

## 7. API endpoints

| Method | URL | Access | Purpose |
|---|---|---|---|
| GET | `?resource=destinations` | Public | List published destinations |
| GET | `?resource=destinations&q=beach` | Public | Search destinations |
| POST | `?resource=auth&action=register` | Public | Register a regular account |
| POST | `?resource=auth&action=login` | Public | Sign in and receive a bearer token |
| GET | `?resource=auth&action=me` | Signed in | Validate current session |
| POST | `?resource=activity` | Signed in | Record a user's app activity |
| GET | `?resource=admin&action=overview` | Admin | Read dashboard totals |
| GET | `?resource=admin&action=users&page=1&limit=25` | Admin | List registered users with activity counts and last login |
| GET | `?resource=admin&action=activities&page=1&limit=25` | Admin | List user activity history, newest first |
| POST | `?resource=auth&action=logout` | Signed in | Revoke current token |
| POST | `?resource=destinations` | Admin | Add destination |
| PUT | `?resource=destinations&id=DESTINATION_ID` | Admin | Update destination |
| DELETE | `?resource=destinations&id=DESTINATION_ID` | Admin | Delete destination |

Admin endpoints require `Authorization: Bearer YOUR_TOKEN`. Tokens are stored as SHA-256 hashes in MySQL and expire after 12 hours. Passwords are stored using PHP's `password_hash()` and verified using `password_verify()`.

## 8. Administrator user directory and activity history

After promoting your own account to `admin`, open the Admin dashboard. It now has sections for **Overview**, **All users**, **User activities**, and **Destinations**.

- **All users** shows the registered account ID implicitly through the record, name, email, role, registration date, last successful login, and activity count. The directory is paginated (25 users per page by default) and can be searched by name, email, or role.
- **User activities** lists registered users' recorded actions, newest first. It includes account registration, successful sign-in/sign-out, destination search and viewing, favorite add/remove, offline-save add/remove, marking a destination visited, and itinerary save/remove. Activity history can be searched and paginated.
- **Overview** shows totals for registered users, administrators, active users in the last 30 days, destinations, total activities, and activities today.
- **Destination management** remains available in the same dashboard.

Activity records belong to the authenticated user whose bearer token submitted the event. The website requires authentication before any tourism page is shown, so guest browsing is disabled and only signed-in user actions are included in this activity history. The starter does not collect IP addresses, passwords, password hashes, or bearer tokens for the activity view. Inform users that their signed-in actions are recorded for system administration and evaluation.

For an existing MySQL database, import `backend/sql/admin_activity_upgrade.sql` once through phpMyAdmin. For a new installation, use the updated `backend/sql/database.sql` instead.

The `activity_logs` table is append-only through the provided API: regular users can submit only their own allow-listed event types, while only admins can list activity records. Do not expose the admin API token in client-side logs or screenshots.

## 9. Offline support and mapping

Offline support is implemented, not simulated.

- **Tourism content**: after a successful API load, the complete destination catalogue is written to IndexedDB (`bohol_explorer_offline`). It is read back at startup before the network is contacted, so the guide opens with cached records when the API or internet is unavailable.
- **Photos**: destination images are cached in IndexedDB the first time they load (and when a destination is saved offline), so viewed destinations keep their photos offline.
- **Offline session**: the signed-in account profile and token are cached locally. A returning visitor can reopen the website while offline; actions that need the PHP API (admin changes, activity logging, fresh data) remain unavailable until it reconnects.
- **Offline map**: the Offline Guide Center and Map screen can download Bohol overview tiles at zoom 10–13 plus a closer zoom-14 block around each destination. Tiles are stored in IndexedDB and preferred over the network, so markers and location guides remain visible offline.
- **App shell**: `web/service_worker.js` caches the compiled Flutter app after the first visit, and `web/flutter_bootstrap.js` starts Flutter without its self-unregistering default worker. A reload with no network still opens the website.
- **Status and sync**: the app listens to the browser online/offline events, shows a banner, and refreshes the cached catalogue automatically when the connection returns.

Map data is © OpenStreetMap contributors, available under the Open Database License. The download is intentionally limited to a small area and a few zoom levels to respect the OpenStreetMap tile usage policy. It is not a complete navigation dataset and must not be used for turn-by-turn navigation. Cached fees, opening hours, and schedules can become outdated; confirm them with the destination or operator.

### Testing offline access

Service workers do not run under `flutter run`, so test the release build through a static server:

1. Sign in once while XAMPP and the internet are available.
2. Open **Map**, wait for tiles to appear, then open the **Offline guide center** and select **Download offline map**.
3. In the browser developer tools, open **Application → IndexedDB → bohol_explorer_offline** and confirm that the `kv`, `tiles`, and `images` stores contain records.
4. Switch the browser network to **Offline** (or stop XAMPP and disconnect the network), then reload the page. The app shell, sign-in session, cached destinations, photos, and downloaded map tiles should still load.
5. Confirm that the orange offline banner appears, search and filtering still work on cached records, and the map shows the downloaded area.
6. Restore the network and confirm the banner disappears and cached tourism information refreshes.

To serve the release build locally:

```bash
flutter build web --release
flutter run -d web-server --web-port 8124   # quick UI check (no service worker)
# For the offline app shell, serve build/web over HTTP, for example:
dart run tool/serve_web.dart 8123
```

Then open `http://localhost:8123`. Clearing the site's storage removes the offline catalogue, photos, tiles, and cached session.

## 10. Important deployment security steps

Before public deployment:

- Change the database credentials and use a dedicated MySQL database user instead of the XAMPP root account.
- Replace the wildcard CORS origin in `backend/api/index.php` with your exact website origin.
- Serve the site and API over HTTPS.
- Add rate limiting and stronger login abuse protection.
- Keep PHP error details out of public responses and inspect server logs privately.
- Back up the MySQL database.
- Validate image URLs and uploaded files before adding file-upload functionality.

## 11. Current limitations

Favorites and itinerary saves are stored in browser preferences (their user actions are logged, but their records are not synchronized as relational MySQL data). Reviews CRUD and itinerary CRUD endpoints are not included. Offline map coverage is a limited Bohol overview plus small destination areas rather than a full tile pack, and the app shell cache is tied to the browser's storage quota. The PHP API cannot be used offline; only previously cached tourism content and account sessions are available.

The nine sample destination records now use destination-specific Wikimedia Commons image URLs and updated map pins. Read `DESTINATION_IMAGE_CREDITS.md` for image authors/licences and `DESTINATION_LOCATIONS.md` for the coordinate reference notes. Images are loaded from Wikimedia over the internet, so they do not load offline unless separately cached. Map pins are reference points for the listed visitor areas, not survey-grade property boundaries. Verify all coordinates on-site or with the destination operator before using them for turn-by-turn navigation. Fees, opening hours, and local visitor policies must also be verified before thesis evaluation or public release.

## Updated sign-in and registration design

The mandatory authentication page now uses a responsive split layout inspired by the supplied reference: a Bohol travel-photo panel on the left and a clean account form on the right. On narrow screens, it changes to a compact photo header above the form. Both sign-in and registration continue to use the existing PHP REST API; no Firebase services are used.

The left panel uses a Pexels photo of the Panglao coastline by Ferdie Cayanga: https://www.pexels.com/photo/top-view-of-a-coastline-with-boats-in-philippines-16812195/ . The photo is loaded from Pexels at runtime, so an internet connection is needed for that background photo. If it cannot load, the panel displays a teal gradient fallback.
