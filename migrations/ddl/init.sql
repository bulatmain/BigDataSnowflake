create schema if not exists model;

-- Category dimension
CREATE TABLE IF NOT EXISTS model.dim_category (
    category_id SERIAL PRIMARY KEY,
    category_name TEXT NOT NULL,
    pet_category TEXT NOT NULL,
    CONSTRAINT uq_category UNIQUE (category_name, pet_category)
);

-- Supplier dimension
CREATE TABLE IF NOT EXISTS model.dim_supplier (
    supplier_id SERIAL PRIMARY KEY,
    supplier_name TEXT NOT NULL,
    contact TEXT,
    email TEXT,
    phone TEXT,
    address TEXT,
    city TEXT,
    country TEXT,
    CONSTRAINT uq_supplier UNIQUE (supplier_name, email, phone)
);	

-- Product dimension
CREATE TABLE IF NOT EXISTS model.dim_product (
    product_id SERIAL PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id INTEGER REFERENCES model.dim_category(category_id),
    price DECIMAL(10,2) NOT NULL,
    quantity INTEGER,
    weight DECIMAL(10,2),
    color TEXT,
    size TEXT,
    brand TEXT,
    material TEXT,
    description TEXT,
    rating DECIMAL(3,1),
    reviews INTEGER,
    release_date DATE,
    expiry_date DATE,
    supplier_id INTEGER REFERENCES model.dim_supplier(supplier_id),
    CONSTRAINT uq_product UNIQUE (product_name, brand, size)
);

-- Store dimension
CREATE TABLE IF NOT EXISTS model.dim_store (
    store_id SERIAL PRIMARY KEY,
    store_name TEXT NOT NULL,
    location TEXT,
    city TEXT,
    state TEXT,
    country TEXT,
    phone TEXT,
    email TEXT,
    CONSTRAINT uq_store UNIQUE (store_name, phone, email)
);

-- Seller dimension
CREATE TABLE IF NOT EXISTS model.dim_seller (
    seller_id SERIAL PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT,
    country TEXT,
    postal_code TEXT,
    CONSTRAINT uq_seller UNIQUE (email)
);

-- Customer dimension
CREATE TABLE IF NOT EXISTS model.dim_customer (
    customer_id SERIAL PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    age INTEGER,
    email TEXT,
    country TEXT,
    postal_code TEXT,
    pet_type TEXT,
    pet_name TEXT,
    pet_breed TEXT,
    CONSTRAINT uq_customer UNIQUE (email)
);

-- Date dimension
CREATE TABLE IF NOT EXISTS model.dim_date (
    date_id SERIAL PRIMARY KEY,
    date DATE NOT NULL UNIQUE,
    day INTEGER NOT NULL,
    month INTEGER NOT NULL,
    year INTEGER NOT NULL,
    quarter INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL,
    day_name TEXT NOT NULL,
    month_name TEXT NOT NULL,
    is_weekend BOOLEAN NOT NULL
);

-- Fact Table

-- Sales fact table
CREATE TABLE IF NOT EXISTS model.fact_sales (
    sale_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES model.dim_customer(customer_id),
    seller_id INTEGER REFERENCES model.dim_seller(seller_id),
    product_id INTEGER REFERENCES model.dim_product(product_id),
    store_id INTEGER REFERENCES model.dim_store(store_id),
    date_id INTEGER REFERENCES model.dim_date(date_id),
    quantity INTEGER NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    CONSTRAINT uq_sale UNIQUE (customer_id, seller_id, product_id, store_id, date_id)
);