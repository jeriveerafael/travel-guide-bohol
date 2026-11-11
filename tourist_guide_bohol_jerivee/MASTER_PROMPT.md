# MASTER PROMPT: TOURIST INFORMATION AND TRAVEL GUIDE MOBILE WEBSITE

## Project title
**Tourist Information and Travel Guide Mobile Website**

## Role
Act as a professional Flutter Web and Dart developer, PHP backend developer, MySQL database designer, UI/UX designer, and software engineer. Build a complete, functional, responsive tourism information and travel guide website focused on Bohol, Philippines, for an Information Technology college thesis.

## Mandatory architecture
Develop a **Flutter Web application** that works in mobile, tablet, and desktop browsers.

Use only this architecture for the backend:
- Frontend: Flutter Web and Dart.
- Backend: PHP 8.1+ REST API.
- Database: MySQL or MariaDB.
- Local development: XAMPP and phpMyAdmin.
- Flutter-to-backend communication: Dart `http` package using JSON REST endpoints.
- Password security: PHP `password_hash()` and `password_verify()`.
- Authentication: PHP API-issued expiring bearer tokens stored as token hashes in MySQL.
- Maps: Flutter Map with an appropriate OpenStreetMap-compatible tile source.
- Local offline content: browser storage such as IndexedDB.

**Do not use Firebase or any Firebase product. Do not add Firebase packages, Firebase configuration files, Firestore, Firebase Authentication, or Firebase Storage.** All server-side user and tourism records must use the PHP REST API and MySQL database.

## Project overview
Create a centralized tourism platform that helps local and foreign tourists, especially first-time visitors, access useful Bohol destination information, search attractions, explore categories, locate destinations, prepare itineraries, and save travel information for offline access.

## Target users
- Local tourists
- Foreign tourists
- First-time visitors
- Travelers planning trips around Bohol
- Website administrators managing tourism content

## Required user-facing features

### 1. Home page
- Welcome and hero section featuring Bohol
- Destination search
- Featured and popular attractions
- Category shortcuts
- Recommended itineraries
- Map preview
- Offline guide information
- Responsive navigation and footer

### 2. Tourism information
Provide organized information about tourist attractions, beaches, historical sites, nature destinations, caves, waterfalls, wildlife and eco-tourism, restaurants, accommodations, transportation, local food, travel tips, and visitor reminders.

Each destination should support name, municipality, category, description, image URL, coordinates, entrance-fee information, operating hours, tips, and directions. Clearly label unknown or unverified visitor details instead of inventing them.

### 3. Search and categories
- Search by destination name and keywords
- Filter by category
- Display results from MySQL through the PHP API
- Open a destination detail page or panel

Suggested categories:
- Nature & Adventure
- Beaches & Islands
- Historical & Cultural
- Caves & Waterfalls
- Wildlife & Eco-Tourism
- Food & Local Experiences

### 4. Maps and location guides
- Interactive map of Bohol
- Destination markers and detail popups
- User location only with permission
- External directions links
- Distance information only when calculated reliably
- Correct map attribution

### 5. Offline information
- Save destinations and itinerary details for offline viewing
- Store downloaded records locally in IndexedDB
- Show online/offline status
- Synchronize cached tourism records when connection returns
- Record download dates and cached data versions

### 6. Offline maps
Implement offline maps only using a provider and web-compatible solution that explicitly permits downloading and storing map data. Do not assume normal online map tiles are downloadable or usable offline. Explain licensing, attribution, storage limits, and technical constraints.

### 7. Itineraries
Provide suggested 1-day, 2-day, and 3-day Bohol itineraries and themed routes. Each itinerary should include destinations, suggested schedule, travel duration, activities, and a clearly labelled estimated budget where reliable data exists. Allow users to save and customize itineraries.

### 8. Interactive features
- Favorites
- Saved offline destinations
- Recently viewed destinations
- Visited destinations
- Share destination details
- Ratings and reviews
- Travel announcements

Persist records in MySQL through the API when signed in; store appropriate offline preferences locally and synchronize them when possible.

## Authentication and roles
Create PHP API endpoints for regular account registration, login, session validation, and logout. Store password hashes, never plaintext passwords. New registrations must always receive the regular `user` role. Only an administrator role verified by the PHP backend may access administrative APIs.

## Administrator dashboard
- Dashboard metrics
- Add, edit, view, and delete destinations
- Manage categories
- Manage itineraries
- Review user ratings and feedback
- Manage registered accounts and roles
- Validate all inputs on both client and server

Do not rely only on hiding admin navigation in Flutter. Enforce administrator authorization in PHP on every write or management endpoint.

## Database requirements
Use MySQL/MariaDB. Provide an importable SQL file with suitable tables, primary keys, foreign keys, indexes, seed categories, and sample Bohol destinations. Include users, API tokens, categories, destinations, itineraries, itinerary destinations, favorites, reviews, and notifications as needed.

Use PDO prepared statements. Provide clear local setup instructions for XAMPP and phpMyAdmin.

## User interface
Use a polished, modern, minimal travel website design with Ocean Blue, Tropical Green, White, Light Gray, Warm Yellow, and Dark Navy. Include responsive layouts, readable typography, accessible controls, loading states, error states, empty states, and consistent cards.

Main navigation: Home, Explore, Destinations, Map, Offline Guide, Itineraries, About, and Login/Profile. Provide an appropriate mobile navigation menu.

## Security
- Use HTTPS in deployment.
- Use PDO prepared statements.
- Hash passwords with PHP's password APIs.
- Use expiring, revocable bearer tokens.
- Enforce roles on the PHP server.
- Validate all inputs and coordinates.
- Configure CORS for the deployed website origin, not wildcard production access.
- Do not expose database credentials in Flutter code.
- Avoid returning raw server errors to public clients.

## Beginner-friendly development instructions
Use Visual Studio Code. Explain Flutter and Dart setup, XAMPP installation, database import, API placement under `htdocs`, PHP configuration, dependencies, folder organization, Flutter run commands, debugging, testing, and deployment.

For every file, provide its exact path, complete code, purpose, and setup instructions. Keep code consistent across files and do not omit necessary imports or dependencies.

## Testing
Provide test cases for registration, login, logout, role checks, destination CRUD, search, categories, map markers, favorites, itinerary management, offline destination viewing, and responsive layouts. Test API authorization directly, not only through the Flutter interface.

## Expected result
Deliver a complete and maintainable Flutter Web tourism website for Bohol connected to a PHP REST API and MySQL database. Prioritize real functionality, security, accurate tourism information, accessibility, and thesis-ready documentation.

Start with architecture and environment setup, then build the project module by module with complete source code. Do not introduce Firebase at any stage.
