-- Step 1: Add new columns
ALTER TABLE users ADD COLUMN IF NOT EXISTS name VARCHAR(150);
ALTER TABLE users ADD COLUMN IF NOT EXISTS roll_no VARCHAR(50);

-- Step 2: Populate name from existing records
UPDATE users 
SET name = TRIM(CONCAT(COALESCE(first_name, ''), ' ', COALESCE(last_name, ''))) 
WHERE name IS NULL OR name = '';

-- Step 3: Populate roll_no for student accounts
UPDATE users 
SET roll_no = UPPER(SPLIT_PART(email, '@', 1))
WHERE role = 'STUDENT' AND (roll_no IS NULL OR roll_no = '');

-- Step 4: Set constraints and drop legacy columns
ALTER TABLE users ALTER COLUMN name SET NOT NULL;
ALTER TABLE users DROP COLUMN IF EXISTS first_name;
ALTER TABLE users DROP COLUMN IF EXISTS last_name;
