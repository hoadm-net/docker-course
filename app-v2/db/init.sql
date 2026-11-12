-- Executed once by the postgres image when the data directory is empty.
CREATE TABLE products (
    id    SERIAL PRIMARY KEY,
    name  TEXT    NOT NULL,
    price INTEGER NOT NULL
);

INSERT INTO products (name, price) VALUES
    ('Headphones', 450000),
    ('Keyboard', 890000),
    ('Cà phê Buôn Ma Thuột', 120000),
    ('Backpack', 350000);
