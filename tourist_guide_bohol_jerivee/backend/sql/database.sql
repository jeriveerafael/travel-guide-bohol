CREATE DATABASE IF NOT EXISTS bohol_tourism_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE bohol_tourism_db;

CREATE TABLE IF NOT EXISTS users (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  full_name VARCHAR(120) NOT NULL,
  email VARCHAR(190) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('user','admin') NOT NULL DEFAULT 'user',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS activity_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NULL,
  event_type VARCHAR(60) NOT NULL,
  description VARCHAR(255) NOT NULL,
  entity_type VARCHAR(60) NULL,
  entity_id VARCHAR(90) NULL,
  metadata_json TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_activity_logs_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_activity_user_created (user_id, created_at),
  INDEX idx_activity_type_created (event_type, created_at),
  INDEX idx_activity_created (created_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS api_tokens (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL,
  token_hash CHAR(64) NOT NULL UNIQUE,
  expires_at DATETIME NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_api_tokens_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS categories (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  description VARCHAR(500) NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS destinations (
  id VARCHAR(90) PRIMARY KEY,
  name VARCHAR(160) NOT NULL,
  municipality VARCHAR(120) NOT NULL,
  category VARCHAR(100) NOT NULL,
  description TEXT NOT NULL,
  image_url VARCHAR(1000) NULL,
  latitude DECIMAL(10,7) NOT NULL,
  longitude DECIMAL(10,7) NOT NULL,
  entrance_fee VARCHAR(255) NULL,
  operating_hours VARCHAR(255) NULL,
  tips TEXT NULL,
  contact_info VARCHAR(500) NULL,
  activities TEXT NULL,
  accommodations TEXT NULL,
  is_published TINYINT(1) NOT NULL DEFAULT 1,
  is_custom TINYINT(1) NOT NULL DEFAULT 0,
  created_by INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_destinations_creator FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_destinations_category (category),
  INDEX idx_destinations_name (name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS itineraries (
  id VARCHAR(90) PRIMARY KEY,
  title VARCHAR(160) NOT NULL,
  description TEXT NOT NULL,
  duration VARCHAR(80) NOT NULL,
  budget_note VARCHAR(500) NULL,
  tag VARCHAR(100) NULL,
  is_published TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS itinerary_destinations (
  itinerary_id VARCHAR(90) NOT NULL,
  destination_id VARCHAR(90) NOT NULL,
  sort_order SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (itinerary_id, destination_id),
  CONSTRAINT fk_itinerary_destination_itinerary FOREIGN KEY (itinerary_id) REFERENCES itineraries(id) ON DELETE CASCADE,
  CONSTRAINT fk_itinerary_destination_destination FOREIGN KEY (destination_id) REFERENCES destinations(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS favorites (
  user_id INT UNSIGNED NOT NULL,
  destination_id VARCHAR(90) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, destination_id),
  CONSTRAINT fk_favorites_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_favorites_destination FOREIGN KEY (destination_id) REFERENCES destinations(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS reviews (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL,
  destination_id VARCHAR(90) NOT NULL,
  rating TINYINT UNSIGNED NOT NULL,
  comment TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chk_review_rating CHECK (rating BETWEEN 1 AND 5),
  CONSTRAINT fk_reviews_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_reviews_destination FOREIGN KEY (destination_id) REFERENCES destinations(id) ON DELETE CASCADE
) ENGINE=InnoDB;

INSERT IGNORE INTO categories (name) VALUES
('Nature & Adventure'), ('Beaches & Islands'), ('Historical & Cultural'),
('Caves & Waterfalls'), ('Wildlife & Eco-Tourism'), ('Food & Local Experiences');

-- Insert or correct destination content on every import. Existing IDs are updated safely.
-- This ensures image URLs and map coordinates are corrected in an existing database.
INSERT INTO destinations
(id,name,municipality,category,description,image_url,latitude,longitude,entrance_fee,operating_hours,tips)
VALUES
('chocolate-hills','Chocolate Hills','Carmen','Nature & Adventure','A famous geological landscape of rounded limestone hills. This map pin points to the Chocolate Hills Complex viewing area in Carmen.','https://upload.wikimedia.org/wikipedia/commons/5/5e/Chocolate_Hills%2C_Carmen%2C_Bohol%2C_Philippines.jpg',9.7986441,124.1674637,'Verify current rates locally','Check current visitor schedule','Bring drinking water and check weather conditions before visiting.'),
('tarsier-sanctuary','Philippine Tarsier Sanctuary','Corella','Wildlife & Eco-Tourism','A conservation-focused visitor site in Corella where guests can learn about the Philippine tarsier and the importance of protecting its habitat.','https://upload.wikimedia.org/wikipedia/commons/3/3d/THE_PHILIPPINE_TARSIER.jpg',9.6913890,123.9530560,'Verify current rates locally','Check current visitor schedule','Follow the sanctuary rules, keep noise low, and do not touch or disturb wildlife.'),
('loboc-river','Loboc River Cruise','Loboc','Nature & Adventure','A scenic river experience known for green surroundings and floating restaurant cruises. The map pin is set at the river cruise information/boarding area in Loboc.','https://upload.wikimedia.org/wikipedia/commons/8/89/Cruising_along_Loboc_River%2C_Bohol.jpg',9.6356900,124.0300600,'Depends on selected activity','Confirm with local operators','Confirm departure times, inclusions, and current prices with the operator before booking.'),
('panglao-island','Dumaluan Beach','Panglao','Beaches & Islands','A white-sand beach area at Dumaluan on Panglao Island, known for its long shoreline and coastal waters. Follow local beach rules and check sea conditions before swimming.','https://upload.wikimedia.org/wikipedia/commons/6/65/Panglao_Island_Beach.jpg',9.5549360,123.7928470,'Varies by location and activity','Varies by establishment','Use reef-safe practices and follow local swimming and boating advisories.'),
('hinagdanan-cave','Hinagdanan Cave','Dauis','Caves & Waterfalls','A limestone cave in Dauis known for its natural formations and underground pool. The marker points to the mapped cave visitor site.','https://upload.wikimedia.org/wikipedia/commons/8/86/Hinagdanan_cave%2C_Bohol.jpg',9.6252800,123.8011100,'Verify current rates locally','Check current visitor schedule','Wear suitable footwear and follow the site staff instructions.'),
('baclayon-church','Baclayon Church','Baclayon','Historical & Cultural','A historic church and cultural landmark in Baclayon. The map marker is positioned by the church entrance; respect worship activities and site rules.','https://upload.wikimedia.org/wikipedia/commons/d/db/Baclayon_church_Bohol.jpg',9.6222330,123.9122000,'Check current museum or visitor fees','Confirm access hours before visiting','Dress respectfully and observe posted visitor guidance.'),
('alona-beach','Alona Beach','Panglao','Beaches & Islands','A popular beachfront area on Panglao Island with nearby restaurants and tourism services. The marker points to the main Alona beachfront area.','https://upload.wikimedia.org/wikipedia/commons/e/e3/Alona_Beach%2C_Panglao.jpg',9.5481500,123.7717300,'Public access conditions may vary','Beach access and businesses vary','Check sea conditions and agree on activity details with registered local operators.'),
('blood-compact-shrine','Blood Compact Shrine','Tagbilaran City','Historical & Cultural','A historical monument in Bool, Tagbilaran City, associated with the Sandugo or blood compact between Datu Sikatuna and Miguel López de Legazpi.','https://upload.wikimedia.org/wikipedia/commons/c/ce/Blood_Compact_Shrine.jpg',9.6274620,123.8792040,'Check local site information','Check current access conditions','Read the historical information displayed at the site.'),
('anda-beach','Anda White Beach','Anda','Beaches & Islands','A coastal destination in eastern Bohol. This map pin is set at the Quinale White Beach area in Anda; confirm local access and beach conditions before travelling.','https://upload.wikimedia.org/wikipedia/commons/3/3a/Andabeach.jpg',9.7425550,124.5763940,'Varies by access point or facility','Varies by access point','Plan transport ahead, especially when travelling from central Bohol.')
ON DUPLICATE KEY UPDATE
name=VALUES(name), municipality=VALUES(municipality), category=VALUES(category),
description=VALUES(description), image_url=VALUES(image_url), latitude=VALUES(latitude), longitude=VALUES(longitude),
entrance_fee=VALUES(entrance_fee), operating_hours=VALUES(operating_hours), tips=VALUES(tips), is_published=1;

-- Travel-guidance content for the seed destinations. Contacts are taken from
-- the official Bohol Provincial Tourism Office municipal pages; verify them
-- before publication. Run destination_guide_upgrade.sql first on old databases.
UPDATE destinations SET
  contact_info = CASE id
    WHEN 'chocolate-hills' THEN 'Carmen Municipal Tourism Office — Glena Berondo · 0951 871 3581 · lgucarmenbohol6319@gmail.com. Bohol Provincial Tourism Office — +63 920 942 6103 · tourismoffice@bohol.gov.ph.'
    WHEN 'tarsier-sanctuary' THEN 'Philippine Tarsier Sanctuary — 0908 937 8094 · joanniemaryc@yahoo.com · Km 14, Canapnapan, Corella. Bohol Provincial Tourism Office — +63 920 942 6103.'
    WHEN 'loboc-river' THEN 'Loboc Tourism — Elmer Varquez · 0951 208 4329 · tourismloboc@gmail.com. Bohol Provincial Tourism Office — +63 920 942 6103.'
    WHEN 'panglao-island' THEN 'Panglao Municipal Tourism — Leonides Senica · 0930 243 2854 / 0909 669 6554 · tourismpanglaocentral@gmail.com. Bohol Provincial Tourism Office — +63 920 942 6103.'
    WHEN 'hinagdanan-cave' THEN 'Dauis Municipal Tourism — Christopher Nistal · 0998 456 5357 · chrisnistal18@gmail.com. Bohol Provincial Tourism Office — +63 920 942 6103.'
    WHEN 'baclayon-church' THEN 'Baclayon Tourism — Maria Teresa A. Indick · 0917 897 1623 · baclayontourism@yahoo.com. Immaculate Conception Parish — (038) 540-9176.'
    WHEN 'alona-beach' THEN 'Panglao Municipal Tourism — Leonides Senica · 0930 243 2854 / 0909 669 6554 · tourismpanglaocentral@gmail.com. Bohol Provincial Tourism Office — +63 920 942 6103.'
    WHEN 'blood-compact-shrine' THEN 'Tagbilaran City Tourism Office — (038) 411-2222 · tagbilarancitytourism@gmail.com. Bohol Provincial Tourism Office — +63 920 942 6103.'
    WHEN 'anda-beach' THEN 'Anda Municipal Tourism — Rouvien De Guzman · 0905 081 3491 · tourismandstatistics@gmail.com. Bohol Provincial Tourism Office — +63 920 942 6103.'
    ELSE contact_info
  END,
  activities = CASE id
    WHEN 'chocolate-hills' THEN 'Hill viewing and photography from the developed viewing deck, plus ATV and zipline experiences run by local operators.'
    WHEN 'tarsier-sanctuary' THEN 'Guided sanctuary walk, tarsier viewing from designated trails, and a conservation briefing before entering.'
    WHEN 'loboc-river' THEN 'Loboc River cruise with local food and music, Loboc Church, and the Loboc Eco-Tourism Adventure Park.'
    WHEN 'panglao-island' THEN 'Swimming and beach walks, island hopping to Balicasag and Virgin Island, snorkeling, and diving.'
    WHEN 'hinagdanan-cave' THEN 'Cave walk to the underground pool, sightseeing, and a stop at the nearby Bohol Bee Farm.'
    WHEN 'baclayon-church' THEN 'Church and museum visit, heritage walk, and a day trip to Pamilacan Island for snorkeling or dolphin watching.'
    WHEN 'alona-beach' THEN 'Swimming, beachfront dining, dive shops, and island-hopping boats departing from the beach.'
    WHEN 'blood-compact-shrine' THEN 'Monument viewing, a short heritage walk, and a Tagbilaran city tour covering nearby churches and museums.'
    WHEN 'anda-beach' THEN 'Quinale Beach swimming, cave-pool visits such as Cabagnow and Combento, and Lamanoc Island tours.'
    ELSE activities
  END,
  accommodations = CASE id
    WHEN 'chocolate-hills' THEN 'Carmen has guesthouses and small hotels; many visitors stay in Tagbilaran City, about 1–1.5 hours away, or in nearby Loboc.'
    WHEN 'tarsier-sanctuary' THEN 'Lodging in Corella is limited; most visitors stay in Tagbilaran City (about 30–40 minutes away) or Sikatuna.'
    WHEN 'loboc-river' THEN 'Riverside lodges and homestays are available in Loboc; Tagbilaran City hotels are about 45 minutes away.'
    WHEN 'panglao-island' THEN 'Beach resorts and guesthouses line Dumaluan and nearby Bolod; Alona Beach offers more hotels, hostels, and restaurants.'
    WHEN 'hinagdanan-cave' THEN 'Dauis and Panglao have resorts and guesthouses; Tagbilaran City is about 20–30 minutes away.'
    WHEN 'baclayon-church' THEN 'Stay in Tagbilaran City (about 15 minutes away) or in Panglao; Baclayon itself has limited lodging.'
    WHEN 'alona-beach' THEN 'Alona Beach has hotels, hostels, and resorts for different budgets; book ahead during peak season.'
    WHEN 'blood-compact-shrine' THEN 'Tagbilaran City has hotels, inns, and pension houses; the shrine is a short tricycle ride from the city center.'
    WHEN 'anda-beach' THEN 'Anda has beachfront resorts and guesthouses; public transport is limited, so arrange transfers in advance.'
    ELSE accommodations
  END
WHERE id IN ('chocolate-hills','tarsier-sanctuary','loboc-river','panglao-island','hinagdanan-cave','baclayon-church','alona-beach','blood-compact-shrine','anda-beach');

INSERT IGNORE INTO itineraries (id,title,description,duration,budget_note,tag) VALUES
('classic-one-day','Classic Bohol Day Tour','A sample route for first-time visitors interested in nature and local culture.','1 day','Costs depend on transport, meals, entrance fees, and selected activities.','First-time visit'),
('panglao-two-day','Panglao and Island Escape','A relaxed sample plan focused on coastal areas and nearby attractions.','2 days','Check accommodation, boat activity, and local transport prices.','Beaches');

INSERT IGNORE INTO itinerary_destinations (itinerary_id,destination_id,sort_order) VALUES
('classic-one-day','blood-compact-shrine',1),('classic-one-day','baclayon-church',2),('classic-one-day','loboc-river',3),('classic-one-day','chocolate-hills',4),
('panglao-two-day','alona-beach',1),('panglao-two-day','panglao-island',2),('panglao-two-day','hinagdanan-cave',3);

-- After registering your first account through the API, promote that account:
-- UPDATE users SET role = 'admin' WHERE email = 'your-email@example.com';
