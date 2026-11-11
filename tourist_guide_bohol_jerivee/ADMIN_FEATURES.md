# Administrator: users and activity history

This update extends the existing Flutter Web + PHP REST API + MySQL project. It does not use Firebase.

## 1. Database update

For an existing installation, open phpMyAdmin, select the SQL import option, and import:

`backend/sql/admin_activity_upgrade.sql`

This creates `activity_logs`. It does not delete user or destination records. For a fresh installation, import the updated `backend/sql/database.sql` instead.

## 2. Admin access

Register a normal account through the website, then promote that account in phpMyAdmin:

```sql
UPDATE users
SET role = 'admin'
WHERE email = 'your-email@example.com';
```

Sign out and sign in again to refresh the role in the bearer-token session.

## 3. Dashboard sections

- **Overview**: total users, admins, published destinations, total logged activities, today's activity count, and users active in the last 30 days.
- **All users**: name, email, role, registration time, last successful login, and activity count. Search by name, email, or role. Results are paginated 25 at a time.
- **User activities**: activity history in reverse chronological order. Search by user name, email, event type, or description. Results are paginated 25 at a time.
- **Destinations**: existing add, edit, and delete tools.

The dashboard refresh button reloads the MySQL data.

## 4. Tracked activity events

The system automatically records account registration, successful login, logout, and administrator destination create/update/delete actions. The Flutter application records signed-in user actions for destination searches and views, map opens, favorite add/remove, offline save/remove, visited marking, profile viewing, and itinerary save/remove.

Guest browsing is disabled: users must sign in or register before entering the website. Activity records are therefore associated with authenticated user accounts. Favorites and saved itineraries remain browser-local in this starter; the activity history records that the signed-in user clicked the relevant action, but it does not mean those features have been synchronized across devices.

## 5. Privacy and security

The admin interface shows basic account details and application activity. It never returns password values, password hashes, or API bearer tokens. Activity writes are attached to the currently authenticated account, and only administrators can read the user directory and activity feed. Let users know in your website's privacy notice that signed-in actions are recorded for system administration and thesis evaluation. Review local privacy requirements before production deployment.

## 6. API endpoints

All admin endpoints require `Authorization: Bearer <token>`:

- `GET ?resource=admin&action=overview`
- `GET ?resource=admin&action=users&page=1&limit=25`
- `GET ?resource=admin&action=activities&page=1&limit=25`
- `POST ?resource=activity` (signed-in user only)

The public API base address for the local XAMPP setup is:

`http://localhost/tourist_guide_bohol_api/api/index.php`
