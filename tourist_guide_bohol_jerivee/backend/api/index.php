<?php
declare(strict_types=1);

require_once __DIR__ . '/config.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *'); // Restrict this to your deployed website domain in production.
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Max-Age: 86400');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

function reply(int $status, array $payload): never
{
    http_response_code($status);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function body_json(): array
{
    $raw = file_get_contents('php://input');
    $data = json_decode($raw ?: '{}', true);
    return is_array($data) ? $data : [];
}

function bearer_token(): ?string
{
    $headers = function_exists('getallheaders') ? getallheaders() : [];
    $authorization = $headers['Authorization'] ?? $headers['authorization'] ?? ($_SERVER['HTTP_AUTHORIZATION'] ?? '');
    if (preg_match('/Bearer\s+(.+)/i', $authorization, $matches)) return trim($matches[1]);
    return null;
}

function current_user(PDO $pdo): ?array
{
    $token = bearer_token();
    if (!$token) return null;
    $stmt = $pdo->prepare(
        'SELECT u.id, u.full_name, u.email, u.role FROM api_tokens t JOIN users u ON u.id = t.user_id WHERE t.token_hash = ? AND t.expires_at > NOW() LIMIT 1'
    );
    $stmt->execute([hash('sha256', $token)]);
    $user = $stmt->fetch();
    return $user ?: null;
}

function require_admin(PDO $pdo): array
{
    $user = current_user($pdo);
    if (!$user) reply(401, ['success' => false, 'message' => 'Please sign in again.']);
    if ($user['role'] !== 'admin') reply(403, ['success' => false, 'message' => 'Administrator access is required.']);
    return $user;
}

function log_activity(
    PDO $pdo,
    ?int $userId,
    string $eventType,
    string $description,
    ?string $entityType = null,
    ?string $entityId = null,
    array $metadata = []
): void {
    try {
        $stmt = $pdo->prepare(
            'INSERT INTO activity_logs (user_id, event_type, description, entity_type, entity_id, metadata_json) VALUES (?, ?, ?, ?, ?, ?)'
        );
        $stmt->execute([
            $userId,
            substr($eventType, 0, 60),
            substr($description, 0, 255),
            $entityType === null ? null : substr($entityType, 0, 60),
            $entityId === null ? null : substr($entityId, 0, 90),
            $metadata ? json_encode($metadata, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) : null,
        ]);
    } catch (Throwable $error) {
        // Activity logging must not prevent a successful user action.
        error_log('Activity log error: ' . $error->getMessage());
    }
}

function destination_payload(array $row): array
{
    return [
        'id' => (string)$row['id'],
        'name' => $row['name'],
        'municipality' => $row['municipality'],
        'category' => $row['category'],
        'description' => $row['description'],
        'imageUrl' => $row['image_url'] ?? '',
        'latitude' => (float)$row['latitude'],
        'longitude' => (float)$row['longitude'],
        'entranceFee' => $row['entrance_fee'] ?? 'Check with the destination',
        'operatingHours' => $row['operating_hours'] ?? 'Check before visiting',
        'tips' => $row['tips'] ?? '',
        'contactInfo' => $row['contact_info'] ?? '',
        'activities' => $row['activities'] ?? '',
        'accommodations' => $row['accommodations'] ?? '',
        'isCustom' => (bool)($row['is_custom'] ?? false),
    ];
}

try {
    $pdo = db();
    $resource = $_GET['resource'] ?? '';
    $method = $_SERVER['REQUEST_METHOD'];

    if ($resource === 'destinations') {
        if ($method === 'GET') {
            $search = trim((string)($_GET['q'] ?? ''));
            if ($search !== '') {
                $like = '%' . $search . '%';
                $stmt = $pdo->prepare('SELECT * FROM destinations WHERE is_published = 1 AND (name LIKE ? OR municipality LIKE ? OR category LIKE ? OR description LIKE ? OR activities LIKE ? OR accommodations LIKE ?) ORDER BY name');
                $stmt->execute([$like, $like, $like, $like, $like, $like]);
            } else {
                $stmt = $pdo->query('SELECT * FROM destinations WHERE is_published = 1 ORDER BY name');
            }
            $items = array_map('destination_payload', $stmt->fetchAll());
            reply(200, ['success' => true, 'data' => $items]);
        }

        $admin = require_admin($pdo);
        if ($method === 'POST' || $method === 'PUT') {
            $data = body_json();
            $id = trim((string)($data['id'] ?? $_GET['id'] ?? ''));
            $name = trim((string)($data['name'] ?? ''));
            $municipality = trim((string)($data['municipality'] ?? ''));
            $category = trim((string)($data['category'] ?? ''));
            $description = trim((string)($data['description'] ?? ''));
            $latitude = filter_var($data['latitude'] ?? null, FILTER_VALIDATE_FLOAT);
            $longitude = filter_var($data['longitude'] ?? null, FILTER_VALIDATE_FLOAT);
            if ($id === '' || $name === '' || $municipality === '' || $category === '' || $description === '' || $latitude === false || $longitude === false || $latitude < -90 || $latitude > 90 || $longitude < -180 || $longitude > 180) {
                reply(422, ['success' => false, 'message' => 'Complete all required fields and provide valid coordinates.']);
            }
            $values = [
                $name, $municipality, $category, $description,
                trim((string)($data['imageUrl'] ?? '')),
                $latitude, $longitude,
                trim((string)($data['entranceFee'] ?? 'Check with the destination')),
                trim((string)($data['operatingHours'] ?? 'Check before visiting')),
                trim((string)($data['tips'] ?? '')),
                trim((string)($data['contactInfo'] ?? '')),
                trim((string)($data['activities'] ?? '')),
                trim((string)($data['accommodations'] ?? '')),
            ];
            if ($method === 'POST') {
                $stmt = $pdo->prepare('INSERT INTO destinations (id, name, municipality, category, description, image_url, latitude, longitude, entrance_fee, operating_hours, tips, contact_info, activities, accommodations, is_published, is_custom, created_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, 1, ?)');
                $stmt->execute([$id, ...$values, $admin['id']]);
                log_activity($pdo, (int)$admin['id'], 'admin_destination_created', 'Added destination: ' . $name, 'destination', $id);
                reply(201, ['success' => true, 'message' => 'Destination created.']);
            }
            $stmt = $pdo->prepare('UPDATE destinations SET name=?, municipality=?, category=?, description=?, image_url=?, latitude=?, longitude=?, entrance_fee=?, operating_hours=?, tips=?, contact_info=?, activities=?, accommodations=? WHERE id=?');
            $stmt->execute([...$values, $id]);
            log_activity($pdo, (int)$admin['id'], 'admin_destination_updated', 'Updated destination: ' . $name, 'destination', $id);
            reply(200, ['success' => true, 'message' => 'Destination updated.']);
        }

        if ($method === 'DELETE') {
            $id = trim((string)($_GET['id'] ?? ''));
            if ($id === '') reply(422, ['success' => false, 'message' => 'Destination ID is required.']);
            $find = $pdo->prepare('SELECT name FROM destinations WHERE id = ? LIMIT 1');
            $find->execute([$id]);
            $deletedName = $find->fetchColumn() ?: $id;
            $stmt = $pdo->prepare('DELETE FROM destinations WHERE id = ?');
            $stmt->execute([$id]);
            log_activity($pdo, (int)$admin['id'], 'admin_destination_deleted', 'Deleted destination: ' . $deletedName, 'destination', $id);
            reply(200, ['success' => true, 'message' => 'Destination deleted.']);
        }
        reply(405, ['success' => false, 'message' => 'Method not allowed.']);
    }

    if ($resource === 'activity') {
        if ($method !== 'POST') reply(405, ['success' => false, 'message' => 'Method not allowed.']);
        $user = current_user($pdo);
        if (!$user) reply(401, ['success' => false, 'message' => 'Please sign in to record your activity.']);
        $data = body_json();
        $eventType = trim((string)($data['eventType'] ?? ''));
        $description = trim((string)($data['description'] ?? ''));
        $allowedEvents = [
            'destination_search', 'destination_view', 'favorite_added', 'favorite_removed',
            'offline_destination_saved', 'offline_destination_removed', 'destination_visited',
            'itinerary_saved', 'itinerary_removed', 'map_opened', 'profile_viewed'
        ];
        if (!in_array($eventType, $allowedEvents, true) || $description === '') {
            reply(422, ['success' => false, 'message' => 'Invalid activity details.']);
        }
        $metadata = $data['metadata'] ?? [];
        if (!is_array($metadata)) $metadata = [];
        $encodedMetadata = json_encode($metadata, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        if ($encodedMetadata !== false && strlen($encodedMetadata) > 3000) {
            reply(422, ['success' => false, 'message' => 'Activity details are too large.']);
        }
        log_activity(
            $pdo,
            (int)$user['id'],
            $eventType,
            $description,
            isset($data['entityType']) ? (string)$data['entityType'] : null,
            isset($data['entityId']) ? (string)$data['entityId'] : null,
            $metadata
        );
        reply(201, ['success' => true, 'message' => 'Activity recorded.']);
    }

    if ($resource === 'admin') {
        $admin = require_admin($pdo);
        if ($method !== 'GET') reply(405, ['success' => false, 'message' => 'Method not allowed.']);
        $action = $_GET['action'] ?? 'overview';

        if ($action === 'overview') {
            $users = (int)$pdo->query('SELECT COUNT(*) FROM users')->fetchColumn();
            $admins = (int)$pdo->query("SELECT COUNT(*) FROM users WHERE role = 'admin'")->fetchColumn();
            $destinations = (int)$pdo->query('SELECT COUNT(*) FROM destinations WHERE is_published = 1')->fetchColumn();
            $activities = (int)$pdo->query('SELECT COUNT(*) FROM activity_logs')->fetchColumn();
            $todayActivities = (int)$pdo->query('SELECT COUNT(*) FROM activity_logs WHERE created_at >= CURDATE()')->fetchColumn();
            $activeUsers = (int)$pdo->query('SELECT COUNT(DISTINCT user_id) FROM activity_logs WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)')->fetchColumn();
            reply(200, ['success' => true, 'data' => [
                'totalUsers' => $users,
                'adminUsers' => $admins,
                'totalDestinations' => $destinations,
                'totalActivities' => $activities,
                'todayActivities' => $todayActivities,
                'activeUsers30Days' => $activeUsers,
            ]]);
        }

        if ($action === 'users') {
            $page = max(1, (int)($_GET['page'] ?? 1));
            $limit = max(1, min(100, (int)($_GET['limit'] ?? 25)));
            $offset = ($page - 1) * $limit;
            $search = trim((string)($_GET['q'] ?? ''));
            $where = '';
            $params = [];
            if ($search !== '') {
                $where = ' WHERE u.full_name LIKE ? OR u.email LIKE ? OR u.role LIKE ?';
                $like = '%' . $search . '%';
                $params = [$like, $like, $like];
            }
            $count = $pdo->prepare('SELECT COUNT(*) FROM users u' . $where);
            $count->execute($params);
            $total = (int)$count->fetchColumn();
            $sql = "SELECT u.id, u.full_name AS fullName, u.email, u.role, u.created_at AS createdAt,
                (SELECT COUNT(*) FROM activity_logs a WHERE a.user_id = u.id) AS activityCount,
                (SELECT MAX(a.created_at) FROM activity_logs a WHERE a.user_id = u.id AND a.event_type = 'login') AS lastLoginAt,
                (SELECT MAX(a.created_at) FROM activity_logs a WHERE a.user_id = u.id) AS lastActivityAt
                FROM users u" . $where . " ORDER BY u.created_at DESC LIMIT " . (int)$limit . " OFFSET " . (int)$offset;
            $stmt = $pdo->prepare($sql);
            $stmt->execute($params);
            reply(200, ['success' => true, 'data' => $stmt->fetchAll(), 'pagination' => [
                'page' => $page, 'limit' => $limit, 'total' => $total, 'pages' => max(1, (int)ceil($total / $limit))
            ]]);
        }

        if ($action === 'activities') {
            $page = max(1, (int)($_GET['page'] ?? 1));
            $limit = max(1, min(100, (int)($_GET['limit'] ?? 25)));
            $offset = ($page - 1) * $limit;
            $search = trim((string)($_GET['q'] ?? ''));
            $where = '';
            $params = [];
            if ($search !== '') {
                $where = ' WHERE u.full_name LIKE ? OR u.email LIKE ? OR a.event_type LIKE ? OR a.description LIKE ?';
                $like = '%' . $search . '%';
                $params = [$like, $like, $like, $like];
            }
            $count = $pdo->prepare('SELECT COUNT(*) FROM activity_logs a LEFT JOIN users u ON u.id = a.user_id' . $where);
            $count->execute($params);
            $total = (int)$count->fetchColumn();
            $sql = "SELECT a.id, a.event_type AS eventType, a.description, a.entity_type AS entityType,
                a.entity_id AS entityId, a.created_at AS createdAt, u.id AS userId,
                COALESCE(u.full_name, 'Deleted account') AS fullName, COALESCE(u.email, '') AS email,
                COALESCE(u.role, '') AS role
                FROM activity_logs a LEFT JOIN users u ON u.id = a.user_id" . $where .
                " ORDER BY a.created_at DESC, a.id DESC LIMIT " . (int)$limit . " OFFSET " . (int)$offset;
            $stmt = $pdo->prepare($sql);
            $stmt->execute($params);
            reply(200, ['success' => true, 'data' => $stmt->fetchAll(), 'pagination' => [
                'page' => $page, 'limit' => $limit, 'total' => $total, 'pages' => max(1, (int)ceil($total / $limit))
            ]]);
        }

        reply(404, ['success' => false, 'message' => 'Admin action not found.']);
    }

    if ($resource === 'auth') {
        $action = $_GET['action'] ?? '';
        if ($action === 'register' && $method === 'POST') {
            $data = body_json();
            $name = trim((string)($data['fullName'] ?? ''));
            $email = strtolower(trim((string)($data['email'] ?? '')));
            $password = (string)($data['password'] ?? '');
            if ($name === '' || !filter_var($email, FILTER_VALIDATE_EMAIL) || strlen($password) < 8) {
                reply(422, ['success' => false, 'message' => 'Enter a name, valid email, and password with at least 8 characters.']);
            }
            $stmt = $pdo->prepare('INSERT INTO users (full_name, email, password_hash, role) VALUES (?, ?, ?, \'user\')');
            try { $stmt->execute([$name, $email, password_hash($password, PASSWORD_DEFAULT)]); }
            catch (PDOException $error) {
                if ($error->getCode() === '23000') reply(409, ['success' => false, 'message' => 'That email is already registered.']);
                throw $error;
            }
            $newUserId = (int)$pdo->lastInsertId();
            log_activity($pdo, $newUserId, 'account_registered', 'Created an account', 'user', (string)$newUserId);
            reply(201, ['success' => true, 'message' => 'Account created. You can now sign in.']);
        }
        if ($action === 'login' && $method === 'POST') {
            $data = body_json();
            $email = strtolower(trim((string)($data['email'] ?? '')));
            $password = (string)($data['password'] ?? '');
            $stmt = $pdo->prepare('SELECT id, full_name, email, password_hash, role FROM users WHERE email = ? LIMIT 1');
            $stmt->execute([$email]);
            $user = $stmt->fetch();
            if (!$user || !password_verify($password, $user['password_hash'])) reply(401, ['success' => false, 'message' => 'Email or password is incorrect.']);
            $token = bin2hex(random_bytes(32));
            $tokenHash = hash('sha256', $token);
            $save = $pdo->prepare('INSERT INTO api_tokens (user_id, token_hash, expires_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 12 HOUR))');
            $save->execute([$user['id'], $tokenHash]);
            log_activity($pdo, (int)$user['id'], 'login', 'Signed in to the website', 'user', (string)$user['id']);
            reply(200, ['success' => true, 'token' => $token, 'user' => ['id' => (int)$user['id'], 'fullName' => $user['full_name'], 'email' => $user['email'], 'role' => $user['role']]]);
        }
        if ($action === 'me' && $method === 'GET') {
            $user = current_user($pdo);
            if (!$user) reply(401, ['success' => false, 'message' => 'Session expired.']);
            reply(200, ['success' => true, 'user' => $user]);
        }
        if ($action === 'logout' && $method === 'POST') {
            $token = bearer_token();
            $user = current_user($pdo);
            if ($user) {
                log_activity($pdo, (int)$user['id'], 'logout', 'Signed out of the website', 'user', (string)$user['id']);
            }
            if ($token) {
                $stmt = $pdo->prepare('DELETE FROM api_tokens WHERE token_hash = ?');
                $stmt->execute([hash('sha256', $token)]);
            }
            reply(200, ['success' => true, 'message' => 'Signed out.']);
        }
        reply(404, ['success' => false, 'message' => 'Authentication action not found.']);
    }

    reply(404, ['success' => false, 'message' => 'API resource not found.']);
} catch (Throwable $error) {
    error_log((string)$error);
    reply(500, ['success' => false, 'message' => 'A server error occurred. Check the PHP error log.']);
}
