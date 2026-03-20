-- =============================================================
-- BANCO DE DADOS: E_COMMERCE
-- =============================================================

CREATE DATABASE IF NOT EXISTS e_commerce;

USE e_commerce;

-- =============================================================
-- TABELA: CLIENTS (CLIENTES) — suporta PF (cpf) e PJ (cnpj)
-- =============================================================

CREATE TABLE clients (
    id_client INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    cpf CHAR(11) UNIQUE CHECK (cpf REGEXP '^[0-9]{11}$'),
    cnpj CHAR(14) UNIQUE CHECK (cnpj REGEXP '^[0-9]{14}$'),
    email VARCHAR(100) NOT NULL UNIQUE CHECK (email LIKE '%@%'),
    phone VARCHAR(20),
    address VARCHAR(150) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_client_doc
        CHECK (
            (cpf IS NOT NULL AND cnpj IS NULL) OR
            (cnpj IS NOT NULL AND cpf IS NULL)
        )
);

-- =============================================================
-- TABELA: PRODUCTS (PRODUTOS)
-- =============================================================

CREATE TABLE products (
    id_product INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category ENUM('Hardware', 'Periferico', 'Smartphone') NOT NULL,
    base_price DECIMAL(10,2) NOT NULL,
    rating DECIMAL(3,2) NOT NULL DEFAULT 0 CHECK (rating BETWEEN 0 AND 5),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================
-- TABELA: ORDERS (PEDIDOS)
-- =============================================================

CREATE TABLE orders (
    id_order INT AUTO_INCREMENT PRIMARY KEY,
    id_client INT NOT NULL,
    status ENUM('Cancelado', 'Confirmado', 'Em Processamento', 'Enviado', 'Entregue') NOT NULL DEFAULT 'Em Processamento',
    total_amount DECIMAL(10,2) NOT NULL,
    shipping_price DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_orders_client
        FOREIGN KEY (id_client)
        REFERENCES clients(id_client)
        ON DELETE CASCADE
);

-- =============================================================
-- TABELA: ORDER_ITEMS (ITENS DO PEDIDO)
-- =============================================================

CREATE TABLE order_items (
    id_order INT,
    id_product INT,
    quantity INT NOT NULL DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,

    PRIMARY KEY (id_order, id_product),

    CONSTRAINT fk_oi_order
        FOREIGN KEY (id_order)
        REFERENCES orders(id_order)
        ON DELETE CASCADE,

    CONSTRAINT fk_oi_product
        FOREIGN KEY (id_product)
        REFERENCES products(id_product)
        ON DELETE CASCADE,

    CONSTRAINT chk_quantity
        CHECK (quantity > 0)
);

-- =============================================================
-- TABELA: PAYMENTS (PAGAMENTOS)
-- =============================================================

CREATE TABLE payments (
    id_payment INT AUTO_INCREMENT PRIMARY KEY,
    id_order INT NOT NULL,
    payment_type ENUM('Pix', 'Boleto', 'Cartao') NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    status ENUM('Pendente', 'Aprovado', 'Recusado') DEFAULT 'Pendente',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_payments_order
        FOREIGN KEY (id_order)
        REFERENCES orders(id_order)
        ON DELETE CASCADE
);

-- =============================================================
-- TABELA: DELIVERIES (ENTREGAS)
-- =============================================================

CREATE TABLE deliveries (
    id_delivery INT AUTO_INCREMENT PRIMARY KEY,
    id_order INT NOT NULL UNIQUE,
    tracking_code VARCHAR(50) NOT NULL UNIQUE,
    status ENUM('Aguardando', 'Despachado', 'Em Trânsito', 'Entregue', 'Devolvido') NOT NULL DEFAULT 'Aguardando',
    estimated_date DATE,
    delivered_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_delivery_order
        FOREIGN KEY (id_order)
        REFERENCES orders(id_order)
        ON DELETE CASCADE
);

-- =============================================================
-- TABELA: INVENTORY_LOCAL (LOCAL DO ESTOQUE)
-- =============================================================

CREATE TABLE inventory_local (
    id_inventory_local INT AUTO_INCREMENT PRIMARY KEY,
    location VARCHAR(255) NOT NULL
);

-- =============================================================
-- TABELA: PRODUCT_INVENTORY (PRODUTO-ESTOQUE)
-- =============================================================

CREATE TABLE product_inventory (
    id_product INT,
    id_inventory_local INT,
    quantity INT NOT NULL DEFAULT 0,

    PRIMARY KEY (id_product, id_inventory_local),

    CONSTRAINT fk_pi_product
        FOREIGN KEY (id_product)
        REFERENCES products(id_product)
        ON DELETE CASCADE,

    CONSTRAINT fk_pi_inventory
        FOREIGN KEY (id_inventory_local)
        REFERENCES inventory_local(id_inventory_local)
        ON DELETE CASCADE,

    CONSTRAINT chk_inventory_quantity
        CHECK (quantity >= 0)
);

-- =============================================================
-- TABELA: SELLERS (VENDEDORES/AS)
-- =============================================================

CREATE TABLE sellers (
    id_seller INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    cnpj CHAR(14) UNIQUE,
    cpf CHAR(11) UNIQUE,
    contact VARCHAR(20),
    location VARCHAR(255),

    CONSTRAINT chk_seller_doc
        CHECK (
            (cnpj IS NOT NULL AND cpf IS NULL AND cnpj REGEXP '^[0-9]{14}$') OR
            (cpf IS NOT NULL AND cnpj IS NULL AND cpf REGEXP '^[0-9]{11}$')
        )
);

-- =============================================================
-- TABELA: PRODUCT_SELLER (VENDEDOR-PRODUTO)
-- =============================================================

CREATE TABLE product_seller (
    id_seller INT,
    id_product INT,
    quantity INT NOT NULL DEFAULT 0,
    price DECIMAL(10,2) NOT NULL,

    PRIMARY KEY (id_seller, id_product),

    CONSTRAINT fk_ps_seller
        FOREIGN KEY (id_seller)
        REFERENCES sellers(id_seller)
        ON DELETE CASCADE,

    CONSTRAINT fk_ps_product
        FOREIGN KEY (id_product)
        REFERENCES products(id_product)
        ON DELETE CASCADE,

    CONSTRAINT chk_ps_quantity
        CHECK (quantity >= 0)
);

-- =============================================================
-- TABELA: SUPPLIERS (FORNECEDORES)
-- =============================================================

CREATE TABLE suppliers (
    id_supplier INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    cnpj CHAR(14) NOT NULL UNIQUE CHECK (cnpj REGEXP '^[0-9]{14}$'),
    contact VARCHAR(20)
);

-- =============================================================
-- TABELA: PRODUCT_SUPPLIER (FORNECEDOR-PRODUTO)
-- =============================================================

CREATE TABLE product_supplier (
    id_product INT,
    id_supplier INT,
    supply_price DECIMAL(10,2),

    PRIMARY KEY (id_product, id_supplier),

    CONSTRAINT fk_psup_product
        FOREIGN KEY (id_product)
        REFERENCES products(id_product)
        ON DELETE CASCADE,

    CONSTRAINT fk_psup_supplier
        FOREIGN KEY (id_supplier)
        REFERENCES suppliers(id_supplier)
        ON DELETE CASCADE
);

-- =============================================================
-- ÍNDICES PARA MELHOR PERFORMANCE
-- =============================================================

CREATE INDEX idx_orders_client
ON orders(id_client);

CREATE INDEX idx_payments_order
ON payments(id_order);

CREATE INDEX idx_product_seller_product
ON product_seller(id_product);

CREATE INDEX idx_product_inventory_product
ON product_inventory(id_product);

CREATE INDEX idx_order_items_product
ON order_items(id_product);

CREATE INDEX idx_product_supplier_supplier
ON product_supplier(id_supplier);

CREATE INDEX idx_deliveries_order
ON deliveries(id_order);

-- =============================================================
-- INSERÇÃO DE DADOS
-- =============================================================

-- CLIENTES (PF e PJ)
INSERT INTO clients (full_name, cpf, cnpj, email, phone, address)
VALUES
    ('Cliente Teste', '12345678901', NULL, 'cliente@email.com', '81999990000', 'Rua Teste, 123'),
    ('Lucas Andrade', '12345678911', NULL, 'lucas@gmail.com', '81999990011', 'Rua F, 600'),
    ('Fernanda Rocha', '12345678912', NULL, 'fernanda@gmail.com', '81999990012', 'Rua G, 700'),
    ('Bruno Martins', '12345678913', NULL, 'bruno@gmail.com', '81999990013', 'Rua H, 800'),
    ('Juliana Mendes', '12345678914', NULL, 'juliana@gmail.com', '81999990014', 'Rua I, 900'),
    ('Ricardo Nunes', '12345678915', NULL, 'ricardo@gmail.com', '81999990015', 'Rua J, 1000'),
    ('Patrícia Gomes', '12345678916', NULL, 'patricia@gmail.com', '81999990016', 'Rua K, 1100'),
    ('Rafael Teixeira', '12345678917', NULL, 'rafael@gmail.com', '81999990017', 'Rua L, 1200'),
    ('Camila Freitas', '12345678918', NULL, 'camila@gmail.com', '81999990018', 'Rua M, 1300'),
    ('Gustavo Pinto', '12345678919', NULL, 'gustavo@gmail.com', '81999990019', 'Rua N, 1400'),
    ('Larissa Barros', '12345678920', NULL, 'larissa@gmail.com', '81999990020', 'Rua O, 1500'),
    ('Tech Solutions Ltda', NULL, '11222333000101', 'contato@techsolutions.com', '1133330001', 'Av. Paulista, 1000, SP'),
    ('Gadgets Brasil S.A.', NULL, '22333444000102', 'vendas@gadgetsbr.com', '2133330002', 'Rua do Comércio, 50, RJ'),
    ('InfoShop ME', NULL, '33444555000103', 'infoshop@email.com', '3133330003', 'Av. Afonso Pena, 200, BH'),
    ('MegaTech Distribuidora', NULL, '44555666000104', 'megatech@megatech.com', '4133330004', 'Rua das Flores, 300, CWB'),
    ('SmartBuy EIRELI', NULL, '55666777000105', 'compras@smartbuy.com', '8533330005', 'Av. Beira Mar, 400, FOR');

-- PRODUTOS
INSERT INTO products (name, category, base_price, rating)
VALUES
    ('Produto Hardware', 'Hardware', 1000.00, 4.5),
    ('Produto Periferico', 'Periferico', 100.00, 3.5),
    ('Produto Smartphone', 'Smartphone', 2000.00, 5.0),
    ('Monitor 24"', 'Hardware', 900.00, 4.4),
    ('Cadeira Gamer', 'Hardware', 1200.00, 4.6),
    ('Webcam HD', 'Periferico', 200.00, 4.1),
    ('Headset Gamer', 'Periferico', 350.00, 4.3),
    ('Samsung Galaxy S21', 'Smartphone', 3200.00, 4.7),
    ('Xiaomi Redmi Note', 'Smartphone', 1800.00, 4.5),
    ('Placa de Vídeo RTX', 'Hardware', 4500.00, 4.9),
    ('Memória RAM 16GB', 'Hardware', 300.00, 4.6),
    ('Mousepad RGB', 'Periferico', 80.00, 4.0),
    ('iPhone 12', 'Smartphone', 4200.00, 4.8),
    ('Produto Extra 14', 'Hardware', 500.00, 4.0),
    ('Produto Extra 15', 'Periferico', 150.00, 4.2);

-- PEDIDOS
INSERT INTO orders (id_client, status, total_amount, shipping_price)
VALUES
    (1, 'Confirmado', 1100.00, 10.00),
    (1, 'Cancelado', 100.00, 5.00),
    (2, 'Confirmado', 1800.00, 20.00),
    (3, 'Enviado', 4500.00, 10.00),
    (4, 'Entregue', 600.00, 15.00),
    (5, 'Cancelado', 240.00, 30.00),
    (6, 'Em Processamento', 4200.00, 25.00),
    (7, 'Confirmado', 900.00, 40.00),
    (8, 'Enviado', 3200.00, 12.00),
    (9, 'Entregue', 400.00, 8.00),
    (10, 'Em Processamento', 350.00, 35.00),
    (11, 'Confirmado', 3200.00, 28.00),
    (12, 'Confirmado', 6900.00, 30.00),
    (13, 'Entregue', 3200.00, 15.00),
    (14, 'Em Processamento', 1400.00, 20.00),
    (15, 'Enviado', 9000.00, 50.00),
    (16, 'Confirmado', 4200.00, 25.00),
    (12, 'Entregue', 1800.00, 10.00);

-- ITENS DOS PEDIDOS
INSERT INTO order_items (id_order, id_product, quantity, unit_price)
VALUES
    (1, 1, 1, 1000.00),
    (1, 2, 1, 100.00),
    (2, 2, 1, 100.00),
    (3, 9, 1, 1800.00),
    (4, 10, 1, 4500.00),
    (5, 11, 2, 300.00),
    (6, 12, 3, 80.00),
    (7, 13, 1, 4200.00),
    (8, 4, 1, 900.00),
    (9, 8, 1, 3200.00),
    (10, 12, 5, 80.00),
    (11, 7, 1, 350.00),
    (12, 8, 1, 3200.00),
    (13, 10, 1, 4500.00),
    (13, 11, 8, 300.00),
    (14, 8, 1, 3200.00),
    (15, 6, 3, 200.00),
    (15, 7, 2, 350.00),
    (16, 10, 2, 4500.00),
    (17, 13, 1, 4200.00),
    (18, 9, 1, 1800.00);

-- PAGAMENTOS
INSERT INTO payments (id_order, payment_type, amount, status)
VALUES
    (1, 'Pix', 1110.00, 'Aprovado'),
    (2, 'Boleto', 105.00, 'Recusado'),
    (3, 'Pix', 1820.00, 'Aprovado'),
    (4, 'Cartao', 4510.00, 'Aprovado'),
    (5, 'Cartao', 615.00, 'Aprovado'),
    (6, 'Boleto', 270.00, 'Recusado'),
    (7, 'Pix', 4225.00, 'Pendente'),
    (8, 'Cartao', 940.00, 'Aprovado'),
    (9, 'Pix', 3212.00, 'Aprovado'),
    (10, 'Boleto', 408.00, 'Aprovado'),
    (11, 'Cartao', 385.00, 'Pendente'),
    (12, 'Pix', 3228.00, 'Aprovado'),
    (13, 'Cartao', 6930.00, 'Aprovado'),
    (13, 'Pix', 500.00, 'Aprovado'),
    (14, 'Pix', 3215.00, 'Aprovado'),
    (15, 'Boleto', 1420.00, 'Pendente'),
    (16, 'Cartao', 9050.00, 'Aprovado'),
    (17, 'Pix', 4225.00, 'Aprovado'),
    (18, 'Boleto', 1810.00, 'Aprovado');

-- ENTREGAS
INSERT INTO deliveries (id_order, tracking_code, status, estimated_date, delivered_at)
VALUES
    (1, 'BR100000001BR', 'Entregue', '2026-01-10', '2026-01-09 14:30:00'),
    (2, 'BR100000002BR', 'Devolvido', '2026-01-12', NULL),
    (3, 'BR100000003BR', 'Entregue', '2026-01-15', '2026-01-14 09:00:00'),
    (4, 'BR100000004BR', 'Em Trânsito', '2026-01-20', NULL),
    (5, 'BR100000005BR', 'Entregue', '2026-01-08', '2026-01-07 16:45:00'),
    (6, 'BR100000006BR', 'Devolvido', '2026-01-22', NULL),
    (7, 'BR100000007BR', 'Despachado', '2026-01-25', NULL),
    (8, 'BR100000008BR', 'Entregue', '2026-01-11', '2026-01-10 11:20:00'),
    (9, 'BR100000009BR', 'Em Trânsito', '2026-01-18', NULL),
    (10, 'BR100000010BR', 'Entregue', '2026-01-09', '2026-01-08 13:00:00'),
    (11, 'BR100000011BR', 'Aguardando', '2026-01-28', NULL),
    (12, 'BR100000012BR', 'Entregue', '2026-01-13', '2026-01-12 10:10:00'),
    (13, 'BR200000013BR', 'Entregue', '2026-02-05', '2026-02-04 10:00:00'),
    (14, 'BR200000014BR', 'Entregue', '2026-02-08', '2026-02-07 15:30:00'),
    (15, 'BR200000015BR', 'Aguardando', '2026-02-15', NULL),
    (16, 'BR200000016BR', 'Em Trânsito', '2026-02-12', NULL),
    (17, 'BR200000017BR', 'Despachado', '2026-02-20', NULL),
    (18, 'BR200000018BR', 'Entregue', '2026-02-06', '2026-02-05 09:45:00');

-- LOCAIS DE ESTOQUE
INSERT INTO inventory_local (location)
VALUES
    ('Armazém Curitiba'),
    ('Armazém Porto Alegre'),
    ('Centro BH'),
    ('Depósito Manaus'),
    ('Unidade Brasília'),
    ('Centro Goiânia'),
    ('Depósito Natal'),
    ('Armazém João Pessoa'),
    ('Centro Maceió'),
    ('Depósito Aracaju');

-- ESTOQUE DE PRODUTOS
INSERT INTO product_inventory (id_product, id_inventory_local, quantity)
VALUES
    (1, 1, 10),
    (6, 2, 25),
    (7, 3, 10),
    (8, 4, 40),
    (9, 5, 60),
    (10, 6, 15),
    (11, 7, 20),
    (12, 8, 30),
    (13, 9, 50);

-- VENDEDORES
INSERT INTO sellers (name, cnpj, cpf, contact, location)
VALUES
    ('Empresa Vendedora', '12345678000101', NULL, '1133334444', 'SP'),
    ('Pessoa Vendedora', NULL, '12345678926', '81988887777', 'PE'),
    ('Vendedor 1', '12345678000111', NULL, '1111111111', 'SP'),
    ('Vendedor 2', NULL, '12345678921', '81900000001', 'PE'),
    ('Vendedor 3', '12345678000112', NULL, '2222222222', 'RJ'),
    ('Vendedor 4', NULL, '12345678922', '81900000002', 'PE'),
    ('Vendedor 5', '12345678000113', NULL, '3333333333', 'MG'),
    ('Vendedor 6', NULL, '12345678923', '81900000003', 'PE'),
    ('Vendedor 7', '12345678000114', NULL, '4444444444', 'BA'),
    ('Vendedor 8', NULL, '12345678924', '81900000004', 'PE'),
    ('Vendedor 9', '12345678000115', NULL, '5555555555', 'CE'),
    ('Vendedor 10', NULL, '12345678925', '81900000005', 'PE');

-- PRODUTO-VENDEDOR
INSERT INTO product_seller (id_seller, id_product, quantity, price)
VALUES
    (1, 1, 5, 1050.00),   -- Produto Hardware (base 1000)
    (2, 2, 10, 110.00),   -- Produto Periferico (base 100)
    (3, 6, 10, 210.00),   -- Webcam HD (base 200)
    (4, 7, 5, 370.00),    -- Headset Gamer (base 350)
    (5, 8, 20, 3350.00),  -- Samsung Galaxy S21 (base 3200)
    (6, 9, 30, 1850.00),  -- Xiaomi Redmi Note (base 1800)
    (7, 10, 8, 4600.00),  -- Placa de Vídeo RTX (base 4500)
    (8, 11, 6, 320.00),   -- Memória RAM 16GB (base 300)
    (9, 12, 7, 90.00),    -- Mousepad RGB (base 80)
    (10, 13, 15, 4300.00), -- iPhone 12 (base 4200)
    (11, 14, 9, 520.00),  -- Produto Extra 14 (base 500)
    (12, 15, 4, 160.00);  -- Produto Extra 15 (base 150)

-- FORNECEDORES
INSERT INTO suppliers (name, cnpj, contact)
VALUES
    ('Fornecedor Teste', '11111111000101', '11999990000'),
    ('Fornecedor F', '11111111000111', '11999990011'),
    ('Fornecedor G', '11111111000112', '11999990012'),
    ('Fornecedor H', '11111111000113', '11999990013'),
    ('Fornecedor I', '11111111000114', '11999990014'),
    ('Fornecedor J', '11111111000115', '11999990015'),
    ('Fornecedor K', '11111111000116', '11999990016'),
    ('Fornecedor L', '11111111000117', '11999990017'),
    ('Fornecedor M', '11111111000118', '11999990018'),
    ('Fornecedor N', '11111111000119', '11999990019'),
    ('Fornecedor O', '11111111000120', '11999990020');

-- PRODUTO-FORNECEDOR
INSERT INTO product_supplier (id_product, id_supplier, supply_price)
VALUES
    (1, 1, 800.00),
    (6, 2, 150.00),
    (7, 3, 280.00),
    (8, 4, 2800.00),
    (9, 5, 1500.00),
    (10, 6, 3900.00),
    (11, 7, 240.00),
    (12, 8, 55.00),
    (13, 9, 3500.00),
    (14, 10, 380.00),
    (15, 11, 110.00);

-- =============================================================
-- QUERIES DE CONSULTA
-- =============================================================

-- 1. Quantos pedidos foram feitos por cada cliente?
SELECT
    c.id_client,
    c.full_name,
    COUNT(o.id_order) AS total_pedidos
FROM clients c
LEFT JOIN orders o ON c.id_client = o.id_client
GROUP BY c.id_client, c.full_name
ORDER BY total_pedidos DESC;

-- 2. Qual o valor total gasto por cliente (apenas pedidos confirmados ou entregues)?
SELECT
    c.full_name,
    COUNT(o.id_order) AS pedidos_ativos,
    SUM(o.total_amount) AS subtotal,
    SUM(o.shipping_price) AS total_frete,
    SUM(o.total_amount + o.shipping_price) AS gasto_total
FROM clients c
JOIN orders o ON c.id_client = o.id_client
WHERE o.status IN ('Confirmado', 'Entregue')
GROUP BY c.id_client, c.full_name
ORDER BY gasto_total DESC;

-- 3. Algum vendedor também é fornecedor?
-- Comparação apenas entre CNPJs, pois CPF (11 dígitos) nunca coincide com CNPJ (14 dígitos)
SELECT
    s.name AS vendedor,
    sp.name AS fornecedor,
    s.cnpj AS documento
FROM sellers s
JOIN suppliers sp ON s.cnpj = sp.cnpj;

-- 4. Relação de produtos, fornecedores e margem de lucro (atributo derivado)
SELECT
    p.name AS produto,
    p.category,
    p.base_price AS preco_base,
    sp.name AS fornecedor,
    psup.supply_price AS preco_fornecimento,
    ROUND(p.base_price - psup.supply_price, 2) AS margem_bruta,
    ROUND((p.base_price - psup.supply_price) / p.base_price * 100, 2) AS margem_pct
FROM products p
JOIN product_supplier psup ON p.id_product = psup.id_product
JOIN suppliers sp ON psup.id_supplier = sp.id_supplier
ORDER BY margem_pct DESC;

-- 5. Relação de produtos em estoque por local
SELECT
    p.name AS produto,
    p.category,
    il.location AS local_estoque,
    pi2.quantity AS quantidade_em_estoque
FROM product_inventory pi2
JOIN products p ON pi2.id_product = p.id_product
JOIN inventory_local il ON pi2.id_inventory_local = il.id_inventory_local
ORDER BY p.name, il.location;

-- 6. Produtos com estoque abaixo de 20 unidades
SELECT
    p.name,
    il.location,
    pi2.quantity AS estoque
FROM product_inventory pi2
JOIN products p ON pi2.id_product = p.id_product
JOIN inventory_local il ON pi2.id_inventory_local = il.id_inventory_local
WHERE pi2.quantity < 20
ORDER BY pi2.quantity ASC;

-- 7. Receita por categoria de produto (HAVING)
SELECT
    p.category,
    COUNT(oi.id_order) AS itens_vendidos,
    SUM(oi.quantity * oi.unit_price) AS receita_total,
    AVG(p.rating) AS avaliacao_media
FROM order_items oi
JOIN products p ON oi.id_product = p.id_product
GROUP BY p.category
HAVING receita_total > 1000
ORDER BY receita_total DESC;

-- 8. Status das entregas com código de rastreio
SELECT
    o.id_order,
    c.full_name AS cliente,
    o.status AS status_pedido,
    d.tracking_code AS rastreio,
    d.status AS status_entrega,
    d.estimated_date AS previsao_entrega,
    d.delivered_at AS entregue_em
FROM orders o
JOIN clients c ON o.id_client = c.id_client
JOIN deliveries d ON o.id_order = d.id_order
ORDER BY o.id_order;

-- 9. Pedidos com pagamento aprovado e entrega ainda pendente
SELECT DISTINCT
    o.id_order,
    c.full_name,
    d.status AS status_entrega,
    d.tracking_code
FROM orders o
JOIN clients c ON o.id_client = c.id_client
JOIN deliveries d ON o.id_order = d.id_order
WHERE d.status NOT IN ('Entregue', 'Devolvido')
  AND EXISTS (
      SELECT 1
      FROM payments p
      WHERE p.id_order = o.id_order
        AND p.status = 'Aprovado'
  )
ORDER BY o.id_order;

-- 10. Vendedores com maior estoque disponível (HAVING)
SELECT
    s.name AS vendedor,
    COUNT(ps.id_product) AS qtd_produtos,
    SUM(ps.quantity) AS estoque_total,
    AVG(ps.price) AS preco_medio
FROM product_seller ps
JOIN sellers s ON ps.id_seller = s.id_seller
GROUP BY s.id_seller, s.name
HAVING estoque_total > 0
ORDER BY estoque_total DESC;

-- 11. Distribuição de clientes PF e PJ
SELECT
    CASE
        WHEN cpf IS NOT NULL THEN 'Pessoa Física'
        WHEN cnpj IS NOT NULL THEN 'Pessoa Jurídica'
    END AS tipo_cliente,
    COUNT(*) AS total
FROM clients
GROUP BY tipo_cliente;

-- 12. Ticket médio por forma de pagamento (atributo derivado)
SELECT
    payment_type AS forma_pagamento,
    COUNT(*) AS total_transacoes,
    SUM(amount) AS volume_total,
    ROUND(AVG(amount), 2) AS ticket_medio,
    MIN(amount) AS menor_valor,
    MAX(amount) AS maior_valor
FROM payments
WHERE status = 'Aprovado'
GROUP BY payment_type
ORDER BY ticket_medio DESC;