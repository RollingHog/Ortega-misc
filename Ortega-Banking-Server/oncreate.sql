CREATE TABLE IF NOT EXISTS users(
  user_id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  nick CHAR UNIQUE,
  full_name CHAR,
  race CHAR NOT NULL,
  race2 CHAR NOT NULL DEFAULT(1),
  guild INT NOT NULL DEFAULT(2),
  alive BOOLEAN NOT NULL DEFAULT(TRUE),
  registrator_id INT,
  FOREIGN KEY (race) REFERENCES races (type_id),
  FOREIGN KEY (race2) REFERENCES races (type_id),
  FOREIGN KEY (guild) REFERENCES guild_names (type_id)
);

CREATE TABLE IF NOT EXISTS registrators(
  user_id INT,
  active BOOLEAN NOT NULL DEFAULT(TRUE),
  users BOOLEAN,
  buildings BOOLEAN,
  companies BOOLEAN,
  banking BOOLEAN,
  FOREIGN KEY (user_id) REFERENCES users (user_id)
);

CREATE TABLE IF NOT EXISTS guild_names(
  type_id INTEGER PRIMARY KEY,
  type_name CHAR UNIQUE
);

INSERT INTO guild_names (type_name) VALUES 
  ('номель'),
  ('гражданин'),
  ('Энваль'),
  ('Инрад'),
  ('Мериум'),
  ('Нихтиль'),
  ('Урбус');

CREATE TABLE IF NOT EXISTS buildings(
  building_id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  name CHAR, 
  owner_type INT NOT NULL DEFAULT(1),
  owner_id INT NOT NULL,
  x INT, 
  y INT, 
  z INT,
  s INT,
  FOREIGN KEY (owner_type) REFERENCES building_owner_types (type_id)
);

DROP TABLE IF EXISTS building_owner_types;

CREATE TABLE IF NOT EXISTS building_owner_types(
  type_id INTEGER PRIMARY KEY,
  type_name CHAR UNIQUE
);
  
INSERT INTO building_owner_types (type_name) VALUES 
  ('Город'),
  ('человек'),
  ('компания');

CREATE TABLE IF NOT EXISTS companies(
  company_id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  company_name CHAR NOT NULL, 
  active BOOLEAN NOT NULL DEFAULT(TRUE),
  owner_id INT NOT NULL,
  location_id INT,
  FOREIGN KEY (owner_id) REFERENCES users (user_id),
  FOREIGN KEY (location_id) REFERENCES buildings (building_id)
);

DROP TABLE IF EXISTS acc_types;

DROP TABLE IF EXISTS acc_owner_types;

DROP TABLE IF EXISTS currency_types;

CREATE TABLE IF NOT EXISTS acc_types(
  type_id INTEGER PRIMARY KEY,
  type_name CHAR UNIQUE
);

INSERT INTO acc_types (type_name) VALUES 
  ('свободный'),
  ('дебет'),
  ('кредит'),
  ('кроу');
  
CREATE TABLE IF NOT EXISTS acc_owner_types(
  type_id INTEGER PRIMARY KEY,
  type_name CHAR UNIQUE
);
  
INSERT INTO acc_owner_types (type_name) VALUES 
  ('эмиссия'),
  ('терминал'),
  ('хранилище'),
  ('человек'),
  ('компания');
  
CREATE TABLE IF NOT EXISTS currency_types(
  type_id INTEGER PRIMARY KEY,
  type_name CHAR UNIQUE
);

INSERT INTO currency_types (type_name) VALUES 
  ('главная'),
  ('свободная');
  
CREATE TABLE IF NOT EXISTS storages(
  owner_type INT,
  owner_id INT,
  currency_type INT NOT NULL DEFAULT(1),
  currency_amount INT,
  FOREIGN KEY (owner_type) REFERENCES acc_owner_types (type_id),
  FOREIGN KEY (currency_type) REFERENCES currency_types (type_id)
);

CREATE TABLE IF NOT EXISTS accounts(
  acc_id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  acc_type INT,
  owner_type INT,
  owner_id INT,
  currency_type INT NOT NULL DEFAULT(1),
  currency_amount INT NOT NULL DEFAULT(0),
  additional INT,
  FOREIGN KEY (acc_type) REFERENCES acc_types (type_id),
  FOREIGN KEY (owner_type) REFERENCES acc_owner_types (type_id),
  FOREIGN KEY (currency_type) REFERENCES currency_types (type_id)
);

INSERT INTO accounts (acc_type, owner_type, owner_id, currency_type, additional) VALUES 
  (1, 1, 0, 0, NULL),
  (1, 1, 0, 1, NULL),
  (1, 1, 0, 0, 'РЕЗЕРВ'),
  (1, 1, 0, 0, 'РЕЗЕРВ'),
  (1, 1, 0, 0, 'РЕЗЕРВ'),
  (1, 1, 0, 0, 'РЕЗЕРВ'),
  (1, 1, 0, 0, 'РЕЗЕРВ'),
  (1, 1, 0, 0, 'РЕЗЕРВ'),
  (1, 1, 0, 0, 'РЕЗЕРВ');

CREATE TABLE IF NOT EXISTS cards (
  card_id CHAR PRIMARY KEY NOT NULL,
  active BOOLEAN NOT NULL DEFAULT(TRUE),
  acc_id INT NOT NULL,
  FOREIGN KEY (acc_id) REFERENCES accounts (acc_id)
);

CREATE TABLE IF NOT EXISTS transactions(
  transaction_id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  from_acc INT,
  to_acc INT,
  currency_type INT,
  currency_amount INT,
  operation_datetime DATETIME NOT NULL DEFAULT(datetime('now', 'localtime')),
  FOREIGN KEY (from_acc) REFERENCES accounts (acc_id),
  FOREIGN KEY (to_acc) REFERENCES accounts (acc_id)
  FOREIGN KEY (currency_type) REFERENCES currency_types (type_id)
);

DROP TABLE IF EXISTS races;

CREATE TABLE IF NOT EXISTS races(
  type_id INTEGER PRIMARY KEY AUTOINCREMENT,
  type_name CHAR UNIQUE
);

INSERT INTO races (type_name) VALUES 
  ("Нет"),
  ("Алварий"),
  ("Алчущий"),
  ("Ах'нэр"),
  ("Буфон"),
  ("Гизка"),
  ("Гинерия"),
  ("Глорания"),
  ("Гонканин"),
  ("Гоплон"),
  ("Гуркх"),
  ("Железорожденный"),
  ("Кандорец"),
  ("Киннал"),
  ("Лунд"),
  ("Мергер"),
  ("Минил"),
  ("Нордим"),
  ("Немический гибрид"),
  ("Орхан"),
  ("Оставленный"),
  ("Рыболюд"),
  ("Серв"),
  ("Серка"),
  ("Фамм"),
  ("Фенх"),
  ("Химера"),
  ("Хорданец"),
  ("Цифириал"),
  ("Человек"),
  ("Человек-птица"),
  ("Шифтер"),
  ("Шурп"),
  ("Энлимиец"),
  ("Прочее");

-- CREATE TRIGGER IF NOT EXISTS on_new_user BEFORE INSERT ON users BEGIN
  -- UPDATE cards SET card_id = (SELECT MAX(card_id) FROM cards) + 1 WHERE card_id = NEW.card_id;
-- END;