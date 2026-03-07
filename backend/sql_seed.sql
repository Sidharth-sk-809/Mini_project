-- Neamet seed data for Supabase Postgres
-- Run sql_schema.sql first.

insert into shops (code, name, shop_type, distance_km, delivery_available) values
('green_basket', 'Green Basket', 'Vegetable Shop', 2, true),
('paper_point', 'Paper Point', 'Stationary Shop', 2, true),
('fresh_farm_market', 'Fresh Farm Market', 'Vegetable Shop', 5, true),
('study_world', 'Study World', 'Stationary Shop', 5, true),
('medico_hub', 'Medico Hub', 'Medicine Shop', 5, true),
('city_veggies', 'City Veggies', 'Vegetable Shop', 10, false),
('smart_stationers', 'Smart Stationers', 'Stationary Shop', 10, false),
('pipemaster_tools', 'PipeMaster Tools', 'Plumbing Tools', 10, false),
('bake_house_delight', 'Bake House Delight', 'Bakery', 10, true)
on conflict (code) do nothing;

insert into products (code, name, subtitle, image, price, rating, review_count, description, stock, shop_id)
select
  concat(s.code, '_', row_number() over (partition by s.id order by p.name), '_', replace(lower(p.name), ' ', '_')) as code,
  p.name,
  s.shop_type as subtitle,
  p.image,
  round((p.base_price * p.multiplier)::numeric, 2) as price,
  p.rating,
  p.review_count,
  concat(p.name, ' from ', s.name) as description,
  p.stock,
  s.id
from (
  values
    ('green_basket','Potato','assets/products/Potato.png',42,1.00,4.2,32,12),
    ('green_basket','Tomato','assets/products/Tomato.png',58,1.00,4.3,28,10),
    ('green_basket','Carrot','assets/products/Carrot.png',70,1.00,4.4,31,10),
    ('green_basket','Cabbage','assets/products/Cabbage.png',48,1.00,4.2,24,8),

    ('paper_point','Scale','assets/products/Scale.png',18,1.00,4.2,16,30),
    ('paper_point','Book','assets/products/Notebook.png',38,1.00,4.4,25,20),
    ('paper_point','Pen','assets/products/Pen.png',15,1.00,4.3,22,45),
    ('paper_point','Paper','assets/products/Paper.png',22,1.00,4.1,14,100),
    ('paper_point','Pencil','assets/products/Pencil.png',12,1.00,4.2,19,50),

    ('fresh_farm_market','Potato','assets/products/Potato.png',42,1.08,4.1,20,10),
    ('fresh_farm_market','Tomato','assets/products/Tomato.png',58,1.08,4.2,18,10),
    ('fresh_farm_market','Carrot','assets/products/Carrot.png',70,1.08,4.3,17,9),
    ('fresh_farm_market','Cabbage','assets/products/Cabbage.png',48,1.08,4.1,15,9),

    ('study_world','Scale','assets/products/Scale.png',18,1.06,4.0,11,24),
    ('study_world','Book','assets/products/Notebook.png',38,1.06,4.2,17,15),
    ('study_world','Pen','assets/products/Pen.png',15,1.06,4.1,12,35),
    ('study_world','Paper','assets/products/Paper.png',22,1.06,4.1,14,70),
    ('study_world','Pencil','assets/products/Pencil.png',12,1.06,4.0,11,42),

    ('medico_hub','Paracetamol','assets/products/Paracetamol.png',45,1.12,4.5,41,40),
    ('medico_hub','Cough Syrup','assets/products/Cough Syrup.png',95,1.12,4.4,27,30),
    ('medico_hub','Bandage','assets/products/Bandage.png',30,1.12,4.3,23,60),

    ('city_veggies','Potato','assets/products/Potato.png',42,1.15,4.0,12,8),
    ('city_veggies','Tomato','assets/products/Tomato.png',58,1.15,4.1,13,8),
    ('city_veggies','Carrot','assets/products/Carrot.png',70,1.15,4.1,11,8),
    ('city_veggies','Cabbage','assets/products/Cabbage.png',48,1.15,4.0,10,8),

    ('smart_stationers','Scale','assets/products/Scale.png',18,1.14,4.0,10,20),
    ('smart_stationers','Book','assets/products/Notebook.png',38,1.14,4.1,12,12),
    ('smart_stationers','Pen','assets/products/Pen.png',15,1.14,4.1,12,32),
    ('smart_stationers','Paper','assets/products/Paper.png',22,1.14,4.0,9,60),
    ('smart_stationers','Pencil','assets/products/Pencil.png',12,1.14,4.0,9,35),

    ('pipemaster_tools','Pipe','assets/products/Pipe.png',220,1.20,4.2,19,15),
    ('pipemaster_tools','Tap','assets/products/Tap.png',180,1.20,4.1,17,20),
    ('pipemaster_tools','Wrench','assets/products/Wrench.png',210,1.20,4.3,21,15),
    ('pipemaster_tools','Hammer','assets/products/Hammer.png',260,1.20,4.4,25,12),

    ('bake_house_delight','Bread','assets/products/Bread.png',35,1.09,4.1,15,30),
    ('bake_house_delight','Bun','assets/products/Bun.png',28,1.09,4.0,12,40),
    ('bake_house_delight','Cake','assets/products/Cake.png',180,1.09,4.4,30,20)
) as p(shop_code,name,image,base_price,multiplier,rating,review_count,stock)
join shops s on s.code = p.shop_code
on conflict (code) do nothing;
