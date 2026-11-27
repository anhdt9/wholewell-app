/// Lược đồ CSDL (đặc tả encrypted-db, mục Lược đồ v1).
///
/// Thời điểm: mili giây UTC (`at`) kèm độ lệch múi giờ lúc ghi (`tz_offset`, phút);
/// `day` là YYYY-MM-DD theo giờ địa phương lúc ăn, uống. Lượng chất theo đơn vị chuẩn
/// của gói dữ liệu. Không có cột tên bệnh, tên thuốc; thai kỳ thêm ở giai đoạn 2.
library;

import 'package:sqlite3/sqlite3.dart' show Database;

/// Phiên bản lược đồ bản app này biết.
const currentSchemaVersion = 3;

/// Các bước di chuyển lược đồ mặc định (từ phiên bản n lên n + 1).
final Map<int, void Function(Database db)> defaultDbMigrations = {
  1: (db) {
    db.execute('ALTER TABLE products ADD COLUMN barcode TEXT');
    db.execute(
      'CREATE INDEX IF NOT EXISTS idx_products_barcode ON products (barcode) WHERE barcode IS NOT NULL',
    );
  },
  2: (db) {
    db.execute(
      'ALTER TABLE settings ADD COLUMN has_breakfast INTEGER NOT NULL DEFAULT 1 CHECK (has_breakfast IN (0, 1))',
    );
    db.execute(
      'ALTER TABLE settings ADD COLUMN has_lunch INTEGER NOT NULL DEFAULT 1 CHECK (has_lunch IN (0, 1))',
    );
    db.execute(
      'ALTER TABLE settings ADD COLUMN has_dinner INTEGER NOT NULL DEFAULT 1 CHECK (has_dinner IN (0, 1))',
    );
    db.execute(
      'ALTER TABLE settings ADD COLUMN reminder_show_details INTEGER NOT NULL DEFAULT 0 CHECK (reminder_show_details IN (0, 1))',
    );
  },
};

/// Các câu tạo lược đồ mới nhất (v3), chạy trong một giao dịch khi tạo CSDL mới.
List<String> get schemaCurrent => [
      ...schemaV1.map((s) {
        if (s.contains('CREATE TABLE products (')) {
          return '''
CREATE TABLE products (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  count_unit TEXT NOT NULL
    CHECK (count_unit IN ('tablet', 'capsule', 'softgel', 'sachet', 'drop', 'ml', 'g')),
  units_per_serving REAL NOT NULL CHECK (units_per_serving > 0),
  barcode TEXT,
  created_at INTEGER NOT NULL,
  archived INTEGER NOT NULL DEFAULT 0 CHECK (archived IN (0, 1))
)''';
        }
        if (s.contains('CREATE TABLE settings (')) {
          return '''
CREATE TABLE settings (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  hide_calories INTEGER CHECK (hide_calories IN (0, 1)),
  show_tip_card INTEGER NOT NULL DEFAULT 1 CHECK (show_tip_card IN (0, 1)),
  wake INTEGER NOT NULL DEFAULT 360 CHECK (wake BETWEEN 0 AND 1439),
  breakfast INTEGER NOT NULL DEFAULT 420 CHECK (breakfast BETWEEN 0 AND 1439),
  lunch INTEGER NOT NULL DEFAULT 720 CHECK (lunch BETWEEN 0 AND 1439),
  dinner INTEGER NOT NULL DEFAULT 1140 CHECK (dinner BETWEEN 0 AND 1439),
  sleep INTEGER NOT NULL DEFAULT 1350 CHECK (sleep BETWEEN 0 AND 1439),
  day_times_confirmed INTEGER NOT NULL DEFAULT 0 CHECK (day_times_confirmed IN (0, 1)),
  has_breakfast INTEGER NOT NULL DEFAULT 1 CHECK (has_breakfast IN (0, 1)),
  has_lunch INTEGER NOT NULL DEFAULT 1 CHECK (has_lunch IN (0, 1)),
  has_dinner INTEGER NOT NULL DEFAULT 1 CHECK (has_dinner IN (0, 1)),
  reminder_show_details INTEGER NOT NULL DEFAULT 0 CHECK (reminder_show_details IN (0, 1))
)''';
        }
        return s;
      }),
      'CREATE INDEX IF NOT EXISTS idx_products_barcode ON products (barcode) WHERE barcode IS NOT NULL',
    ];

/// Các câu tạo lược đồ v1, chạy trong một giao dịch.
const schemaV1 = <String>[
  '''
CREATE TABLE meta (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  schema_version INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  onboarding_step TEXT NOT NULL
    CHECK (onboarding_step IN ('body_profile', 'calorie_display', 'done'))
)''',
  '''
CREATE TABLE consents (
  id INTEGER PRIMARY KEY,
  kind TEXT NOT NULL CHECK (kind IN ('health_data', 'notifications', 'drive')),
  content_version TEXT NOT NULL,
  granted_at INTEGER NOT NULL,
  withdrawn_at INTEGER
)''',
  '''
CREATE TABLE profile (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  age_years INTEGER NOT NULL CHECK (age_years BETWEEN 1 AND 120),
  age_entered_on TEXT NOT NULL,
  caution INTEGER NOT NULL CHECK (caution IN (0, 1)),
  caution_answered_on TEXT NOT NULL,
  sex TEXT CHECK (sex IN ('male', 'female')),
  height_cm REAL CHECK (height_cm > 0),
  weight_kg REAL CHECK (weight_kg > 0),
  activity_level TEXT
    CHECK (activity_level IN ('inactive', 'lowActive', 'active', 'veryActive')),
  updated_at INTEGER NOT NULL
)''',
  '''
CREATE TABLE settings (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  hide_calories INTEGER CHECK (hide_calories IN (0, 1)),
  show_tip_card INTEGER NOT NULL DEFAULT 1 CHECK (show_tip_card IN (0, 1)),
  wake INTEGER NOT NULL DEFAULT 360 CHECK (wake BETWEEN 0 AND 1439),
  breakfast INTEGER NOT NULL DEFAULT 420 CHECK (breakfast BETWEEN 0 AND 1439),
  lunch INTEGER NOT NULL DEFAULT 720 CHECK (lunch BETWEEN 0 AND 1439),
  dinner INTEGER NOT NULL DEFAULT 1140 CHECK (dinner BETWEEN 0 AND 1439),
  sleep INTEGER NOT NULL DEFAULT 1350 CHECK (sleep BETWEEN 0 AND 1439),
  day_times_confirmed INTEGER NOT NULL DEFAULT 0 CHECK (day_times_confirmed IN (0, 1))
)''',
  '''
CREATE TABLE products (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  count_unit TEXT NOT NULL
    CHECK (count_unit IN ('tablet', 'capsule', 'softgel', 'sachet', 'drop', 'ml', 'g')),
  units_per_serving REAL NOT NULL CHECK (units_per_serving > 0),
  created_at INTEGER NOT NULL,
  archived INTEGER NOT NULL DEFAULT 0 CHECK (archived IN (0, 1))
)''',
  '''
CREATE TABLE ingredients (
  id INTEGER PRIMARY KEY,
  product_id INTEGER NOT NULL REFERENCES products (id),
  nutrient_id TEXT,
  free_name TEXT,
  form TEXT NOT NULL DEFAULT 'unknown',
  amount_per_serving REAL,
  unit TEXT,
  label_amount REAL,
  label_unit TEXT,
  is_compound INTEGER NOT NULL DEFAULT 0 CHECK (is_compound IN (0, 1)),
  origin TEXT NOT NULL CHECK (origin IN ('manual', 'barcode', 'ocr')),
  confirmed INTEGER NOT NULL DEFAULT 0 CHECK (confirmed IN (0, 1)),
  CHECK (nutrient_id IS NOT NULL OR free_name IS NOT NULL)
)''',
  '''
CREATE TABLE boxes (
  id INTEGER PRIMARY KEY,
  product_id INTEGER NOT NULL REFERENCES products (id),
  remaining REAL NOT NULL CHECK (remaining >= 0),
  expiry_month TEXT CHECK (expiry_month GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]'),
  added_at INTEGER NOT NULL
)''',
  '''
CREATE TABLE schedules (
  id INTEGER PRIMARY KEY,
  product_id INTEGER NOT NULL REFERENCES products (id),
  time_of_day INTEGER NOT NULL CHECK (time_of_day BETWEEN 0 AND 1439),
  servings REAL NOT NULL CHECK (servings > 0),
  valid_from TEXT NOT NULL,
  valid_to TEXT,
  CHECK (valid_to IS NULL OR valid_to >= valid_from)
)''',
  '''
CREATE TABLE dose_entries (
  id INTEGER PRIMARY KEY,
  at INTEGER NOT NULL,
  tz_offset INTEGER NOT NULL,
  day TEXT NOT NULL,
  product_id INTEGER REFERENCES products (id),
  name TEXT,
  kind TEXT NOT NULL CHECK (kind IN ('scheduled', 'extra', 'one_off')),
  servings REAL NOT NULL CHECK (servings > 0),
  pack_version TEXT NOT NULL
)''',
  '''
CREATE TABLE dose_occurrences (
  schedule_id INTEGER NOT NULL REFERENCES schedules (id),
  day TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('taken', 'skipped')),
  dose_entry_id INTEGER UNIQUE REFERENCES dose_entries (id) ON DELETE CASCADE,
  updated_at INTEGER NOT NULL,
  PRIMARY KEY (schedule_id, day),
  CHECK ((status = 'taken') = (dose_entry_id IS NOT NULL))
)''',
  '''
CREATE TABLE dose_box_deductions (
  dose_entry_id INTEGER NOT NULL REFERENCES dose_entries (id) ON DELETE CASCADE,
  box_id INTEGER NOT NULL REFERENCES boxes (id),
  amount REAL NOT NULL CHECK (amount > 0),
  PRIMARY KEY (dose_entry_id, box_id)
)''',
  '''
CREATE TABLE food_entries (
  id INTEGER PRIMARY KEY,
  at INTEGER NOT NULL,
  tz_offset INTEGER NOT NULL,
  day TEXT NOT NULL,
  meal TEXT NOT NULL CHECK (meal IN ('breakfast', 'lunch', 'dinner', 'snack')),
  name TEXT NOT NULL,
  food_ref TEXT,
  portion_unit TEXT NOT NULL,
  portion_qty REAL NOT NULL CHECK (portion_qty > 0),
  label_basis_qty REAL CHECK (label_basis_qty > 0),
  label_basis_unit TEXT,
  added_sugar_known INTEGER NOT NULL CHECK (added_sugar_known IN (0, 1)),
  pack_version TEXT NOT NULL
)''',
  '''
CREATE TABLE custom_foods (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  portion_unit TEXT NOT NULL,
  label_basis_qty REAL NOT NULL CHECK (label_basis_qty > 0),
  label_basis_unit TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  archived INTEGER NOT NULL DEFAULT 0 CHECK (archived IN (0, 1))
)''',
  '''
CREATE TABLE custom_food_lines (
  custom_food_id INTEGER NOT NULL REFERENCES custom_foods (id) ON DELETE CASCADE,
  nutrient_id TEXT NOT NULL,
  form TEXT,
  label_amount REAL NOT NULL,
  label_unit TEXT NOT NULL,
  source TEXT NOT NULL CHECK (source IN ('food', 'fortified'))
)''',
  '''
CREATE TABLE intake_lines (
  id INTEGER PRIMARY KEY,
  food_entry_id INTEGER REFERENCES food_entries (id) ON DELETE CASCADE,
  dose_entry_id INTEGER REFERENCES dose_entries (id) ON DELETE CASCADE,
  day TEXT NOT NULL,
  nutrient_id TEXT,
  free_name TEXT,
  source TEXT NOT NULL CHECK (source IN ('food', 'fortified', 'supplement')),
  form TEXT,
  uncertain INTEGER NOT NULL DEFAULT 0 CHECK (uncertain IN (0, 1)),
  label_amount REAL,
  label_unit TEXT,
  amounts TEXT NOT NULL CHECK (json_valid(amounts)),
  ul_amounts TEXT CHECK (ul_amounts IS NULL OR json_valid(ul_amounts)),
  CHECK ((food_entry_id IS NULL) <> (dose_entry_id IS NULL)),
  CHECK (nutrient_id IS NOT NULL OR free_name IS NOT NULL)
)''',
  '''
CREATE TABLE water_entries (
  id INTEGER PRIMARY KEY,
  at INTEGER NOT NULL,
  tz_offset INTEGER NOT NULL,
  day TEXT NOT NULL,
  ml REAL NOT NULL CHECK (ml > 0)
)''',
  '''
CREATE TABLE workout_entries (
  id INTEGER PRIMARY KEY,
  start_at INTEGER NOT NULL,
  tz_offset INTEGER NOT NULL,
  day TEXT NOT NULL,
  activity_code TEXT NOT NULL,
  minutes REAL NOT NULL CHECK (minutes > 0)
)''',
  '''
CREATE TABLE ui_state (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
)''',
  'CREATE INDEX food_entries_day ON food_entries (day)',
  'CREATE INDEX dose_entries_day ON dose_entries (day)',
  'CREATE INDEX intake_lines_day ON intake_lines (day)',
  'CREATE INDEX intake_lines_food ON intake_lines (food_entry_id)',
  'CREATE INDEX intake_lines_dose ON intake_lines (dose_entry_id)',
  'CREATE INDEX water_entries_day ON water_entries (day)',
  'CREATE INDEX workout_entries_day ON workout_entries (day)',
  'CREATE INDEX boxes_product ON boxes (product_id)',
  'CREATE INDEX schedules_product ON schedules (product_id)',
  'CREATE INDEX ingredients_product ON ingredients (product_id)',
  'CREATE INDEX dose_box_deductions_box ON dose_box_deductions (box_id)',
];
