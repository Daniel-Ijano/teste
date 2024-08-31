// 1. Listar todos Clientes que não tenham realizado uma compra
// Premissa: Atuação dos times de marketing e comercial a nível de estado e município (output)
WITH
q_orders AS(
  SELECT customer_id, COUNT(DISTINCT order_id) AS count_orders
  FROM "Sales"."orders"
  GROUP BY customer_id
) // Tabela temporária com contagem de orders por customer
SELECT * EXCEPT(count_orders)
FROM(
  SELECT
  A."state",
  A.city, 
  A.customer_id,
  A.first_name || ' ' || A.last_name AS customer_name, // Concatenate Nome completo
  B.count_orders
  FROM "Sales"."customers" A
  LEFT JOIN q_orders B
  ON A.customer_id = B.customer_id // Join utilizando o campo customer_id como chave
)
WHERE count_orders IS NULL OR count_orders =0 // Filtrar os casos em que não foram localizadas ordens de venda
ORDER BY "state", city, customer_name // Separar a lista em blocos por estado e cidade
;


//2. Listar os Produtos que não tenham sido comprados
WITH
q_orders AS(
  SELECT product_id, COUNT(DISTINCT order_id) AS count_orders
  FROM "Sales"."order_items"
  GROUP BY product_id
) // Tabela temporária com contagem de orders por produto
SELECT * EXCEPT(count_orders)
FROM(
  SELECT
  C.category_name,
  B.brand_name,
  A.product_id,
  A.product_name,
  D.count_orders
  FROM "Production"."products" A
  LEFT JOIN "Production"."brands" B ON A.brand_id = B.brand_id
  LEFT JOIN "Production"."categories" C ON A.category_id = C.category_id
  LEFT JOIN q_orders D ON A.product_id = D.product_id
  // Join utilizando o campo product_id como chave
)
WHERE count_orders IS NULL OR count_orders =0 // Filtrar os casos em que não foram localizadas ordens de venda
ORDER BY category_name, brand_name, product_name // Separar a lista em blocos por category e brand
;

//3. Listar os Produtos sem Estoque;
WITH
q_stock AS(
  SELECT product_id, SUM(quantity) AS stock_qty
  FROM "Production"."stocks"
  GROUP BY product_id
) // Tabela temporária com soma do estoque por produto
SELECT * EXCEPT(stock_qty)
FROM(
  SELECT
  C.category_name,
  B.brand_name,
  A.product_id,
  A.product_name,
  D.stock_qty
  FROM "Production"."products" A
  LEFT JOIN "Production"."brands" B ON A.brand_id = B.brand_id
  LEFT JOIN "Production"."categories" C ON A.category_id = C.category_id
  LEFT JOIN q_stock D ON A.product_id = D.product_id
  // Join utilizando o campo product_id como chave
)
WHERE stock_qty IS NULL OR stock_qty =0 // Filtrar os casos em que não foi localizado saldo em estoque
ORDER BY category_name, brand_name, product_name // Separar a lista em blocos por category e brand
;

//4. Agrupar a quantidade de vendas de uma determinada Marca por Loja.
// Premissa: discount é um valor $ e não porcentagem
WITH
q_product AS(
  SELECT DISTINCT A.product_id, B.brand_name
  FROM "Production"."products" A
  LEFT JOIN "Production"."brands" B ON A.brand_id = B.brand_id
),
q_orders AS(
  SELECT DISTINCT A.order_id, B.store_name
  FROM "Sales"."orders" A
  LEFT JOIN "Sales"."stores" B ON A.store_id = B.store_id
),
q_revenue AS(
  SELECT order_id, product_id,
  SUM((quantity * list_price) - discount) AS revenue
  FROM "Sales"."order_items"
  GROUP BY order_id, product_id
  ORDER BY order_id, product_id
)
SELECT B.store_name, C.brand_name, A.revenue
FROM q_revenue A
LEFT JOIN q_orders B ON A.order_id = B.order_id
LEFT JOIN q_product C ON A.product_id = C.product_iD
;

//5. Listar os Funcionarios que não estejam relacionados a um Pedido.
//Seria interessante ter o nome do gerente no relatório para facilitar as ações, porém temos acesso apenas ao id
WITH
q_orders AS(
  SELECT staff_id, COUNT(DISTINCT order_id) AS count_orders
  FROM "Sales"."orders"
  GROUP BY staff_id
) // Tabela temporária com contagem de orders por staff (colaborador)
SELECT * EXCEPT(count_orders)
FROM(
  SELECT
  A.manager_id,
  B.store_name,
  A.staff_id,
  A.first_name || ' ' || A.last_name AS staff_name, // Concatenate Nome completo
  C.count_orders
  FROM "Sales"."staffs" A
  LEFT JOIN "Sales"."stores" B ON A.store_id = B.store_id
  LEFT JOIN q_orders C ON A.staff_id = C.staff_id
  // Join utilizando o campo staff_id como chave
  WHERE A.active = 'Yes' // (premissa de que os valores desse campo sejam Yes/No)
)
WHERE count_orders IS NULL OR count_orders =0 // Filtrar os casos em que não foram localizadas ordens de venda
ORDER BY manager_id, store_name, staff_name // Separar a lista em blocos por manager e store
;
