-- First populate dim_category (needed for dim_product)
INSERT INTO model.dim_category (category_name, pet_category)
SELECT DISTINCT 
    product_category,
    pet_category
FROM import_csv.mock_data
WHERE product_category IS NOT NULL
ON CONFLICT ON CONSTRAINT uq_category DO NOTHING;

-- Populate dim_supplier (needed for dim_product)
INSERT INTO model.dim_supplier (
    supplier_name, contact, email, phone, address, city, country
)
SELECT DISTINCT
    supplier_name,
    supplier_contact,
    supplier_email,
    supplier_phone,
    supplier_address,
    supplier_city,
    supplier_country
FROM import_csv.mock_data
WHERE supplier_name IS NOT NULL
ON CONFLICT ON CONSTRAINT uq_supplier DO NOTHING;

-- Populate dim_product
INSERT INTO model.dim_product (
    product_name, category_id, price, quantity, weight, color, size,
    brand, material, description, rating, reviews, release_date,
    expiry_date, supplier_id
)
SELECT DISTINCT
    md.product_name,
    c.category_id,
    md.product_price,
    md.product_quantity,
    md.product_weight,
    md.product_color,
    md.product_size,
    md.product_brand,
    md.product_material,
    md.product_description,
    md.product_rating,
    md.product_reviews,
    TO_DATE(md.product_release_date, 'MM/DD/YYYY'),
    TO_DATE(md.product_expiry_date, 'MM/DD/YYYY'),
    s.supplier_id
FROM import_csv.mock_data md
JOIN model.dim_category c ON md.product_category = c.category_name AND md.pet_category = c.pet_category
JOIN model.dim_supplier s ON md.supplier_name = s.supplier_name
    AND (md.supplier_email = s.email OR (md.supplier_email IS NULL AND s.email IS NULL))
    AND (md.supplier_phone = s.phone OR (md.supplier_phone IS NULL AND s.phone IS NULL))
WHERE md.product_name IS NOT NULL
ON CONFLICT ON CONSTRAINT uq_product DO NOTHING;

-- Populate dim_store
INSERT INTO model.dim_store (
    store_name, location, city, state, country, phone, email
)
SELECT DISTINCT
    store_name,
    store_location,
    store_city,
    store_state,
    store_country,
    store_phone,
    store_email
FROM import_csv.mock_data
WHERE store_name IS NOT NULL
ON CONFLICT ON CONSTRAINT uq_store DO NOTHING;

-- Populate dim_seller
INSERT INTO model.dim_seller (
    first_name, last_name, email, country, postal_code
)
SELECT DISTINCT
    seller_first_name,
    seller_last_name,
    seller_email,
    seller_country,
    seller_postal_code
FROM import_csv.mock_data
WHERE seller_first_name IS NOT NULL OR seller_last_name IS NOT NULL
ON CONFLICT ON CONSTRAINT uq_seller DO NOTHING;

-- Populate dim_customer
INSERT INTO model.dim_customer (
    first_name, last_name, age, email, country, postal_code,
    pet_type, pet_name, pet_breed
)
SELECT DISTINCT
    customer_first_name,
    customer_last_name,
    customer_age,
    customer_email,
    customer_country,
    customer_postal_code,
    customer_pet_type,
    customer_pet_name,
    customer_pet_breed
FROM import_csv.mock_data
WHERE customer_first_name IS NOT NULL OR customer_last_name IS NOT NULL
ON CONFLICT ON CONSTRAINT uq_customer DO NOTHING;


-- First insert all distinct dates from the sales data
INSERT INTO model.dim_date (date, day, month, year, quarter, day_of_week, day_name, month_name, is_weekend)
WITH distinct_dates AS (
    SELECT DISTINCT TO_DATE(sale_date, 'MM/DD/YYYY') AS sale_date
    FROM import_csv.mock_data
    WHERE sale_date IS NOT NULL
)
SELECT
    sale_date AS date,
    EXTRACT(DAY FROM sale_date) AS day,
    EXTRACT(MONTH FROM sale_date) AS month,
    EXTRACT(YEAR FROM sale_date) AS year,
    EXTRACT(QUARTER FROM sale_date) AS quarter,
    EXTRACT(DOW FROM sale_date) AS day_of_week,
    TO_CHAR(sale_date, 'Day') AS day_name,
    TO_CHAR(sale_date, 'Month') AS month_name,
    EXTRACT(DOW FROM sale_date) IN (0, 6) AS is_weekend
FROM distinct_dates
ON CONFLICT (date) DO NOTHING;

-- Finally populate the fact_sales table
INSERT INTO model.fact_sales (
    customer_id, seller_id, product_id, store_id, date_id,
    quantity, total_price
)
SELECT
    c.customer_id,
    s.seller_id,
    p.product_id,
    st.store_id,
    d.date_id,
    md.sale_quantity,
    md.sale_total_price
FROM import_csv.mock_data md
JOIN model.dim_customer c ON 
    (md.customer_email = c.email OR (md.customer_email IS NULL AND c.email IS NULL))
    AND (md.customer_first_name = c.first_name OR (md.customer_first_name IS NULL AND c.first_name IS NULL))
    AND (md.customer_last_name = c.last_name OR (md.customer_last_name IS NULL AND c.last_name IS NULL))
JOIN model.dim_seller s ON 
    (md.seller_email = s.email OR (md.seller_email IS NULL AND s.email IS NULL))
    AND (md.seller_first_name = s.first_name OR (md.seller_first_name IS NULL AND s.first_name IS NULL))
    AND (md.seller_last_name = s.last_name OR (md.seller_last_name IS NULL AND s.last_name IS NULL))
JOIN model.dim_product p ON 
    md.product_name = p.product_name
    AND (md.product_brand = p.brand OR (md.product_brand IS NULL AND p.brand IS NULL))
    AND (md.product_size = p.size OR (md.product_size IS NULL AND p.size IS NULL))
JOIN model.dim_store st ON 
    md.store_name = st.store_name
    AND (md.store_phone = st.phone OR (md.store_phone IS NULL AND st.phone IS NULL))
    AND (md.store_email = st.email OR (md.store_email IS NULL AND st.email IS NULL))
JOIN model.dim_date d ON TO_DATE(md.sale_date, 'MM/DD/YYYY') = d.date
WHERE md.sale_quantity IS NOT NULL;