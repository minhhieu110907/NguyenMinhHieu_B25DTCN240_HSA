CREATE DATABASE garden_management;
USE garden_management;

-- TẠO BẢNG Zones
CREATE TABLE Zones (
    zone_id VARCHAR(5) PRIMARY KEY NOT NULL,
    zone_name VARCHAR(100) NOT NULL,
    area_square_meters DECIMAL(10,2) NOT NULL,
    light_condition VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL,
    CONSTRAINT chk_area CHECK (area_square_meters > 0)
);

-- TẠO BẢNG Crops
CREATE TABLE Crops (
    crop_id VARCHAR(5) PRIMARY KEY NOT NULL,
    crop_name VARCHAR(100) NOT NULL UNIQUE,
    growth_time_days INT NOT NULL,
    water_requirement VARCHAR(50) NOT NULL,
    expected_yield DECIMAL(10,2) NOT NULL
);

-- TẠO BẢNG Planting_Logs
CREATE TABLE Planting_Logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    zone_id VARCHAR(5) NOT NULL,
    crop_id VARCHAR(5) NOT NULL,
    planting_date DATE NOT NULL,
    last_watered DATETIME,
    is_automated BOOLEAN NOT NULL DEFAULT 1,
    CONSTRAINT uq_zone_crop UNIQUE (zone_id, crop_id),
    FOREIGN KEY (zone_id) REFERENCES Zones(zone_id),
    FOREIGN KEY (crop_id) REFERENCES Crops(crop_id)
);

-- TẠO BẢNG Harvests
CREATE TABLE Harvests (
    harvest_id INT AUTO_INCREMENT PRIMARY KEY,
    log_id INT NOT NULL,
    harvest_date DATE NOT NULL,
    actual_yield DECIMAL(10,2) NOT NULL,
    quality_grade VARCHAR(10) NOT NULL,
    FOREIGN KEY (log_id) REFERENCES Planting_Logs(log_id)
);

-- THÊM BẢNG Zones
INSERT INTO Zones VALUES
('Z01', 'Khu nhà màng 01', 50.5, 'Full Sun', 'Occupied'),
('Z02', 'Khu thủy canh 02', 30.0, 'Partial Shade', 'Occupied'),
('Z03', 'Vườn rau gia vị', 15.0, 'Full Sun', 'Available'),
('Z04', 'Nhà kính trung tâm', 100.0, 'Full Sun', 'Occupied'),
('Z05', 'Khu thực nghiệm', 25.0, 'Shade', 'Maintenance');

-- THÊM BẢNG Crops
INSERT INTO Crops VALUES
('C01', 'Xà lách thủy tinh', 45, 'High', 2.5),
('C02', 'Cà chua Cherry', 90, 'Medium', 5.0),
('C03', 'Cải bó xôi', 35, 'High', 1.8),
('C04', 'Dưa lưới Nhật', 85, 'Medium', 4.0),
('C05', 'Ớt chuông', 110, 'Medium', 3.5);

-- THÊM BẢNG Planting Logs
INSERT INTO Planting_Logs (log_id, zone_id, crop_id, planting_date, last_watered, is_automated) VALUES
(1, 'Z01', 'C02', '2025-10-01', '2025-11-10 08:00:00', 1),
(2, 'Z02', 'C01', '2025-11-05', '2025-11-10 17:30:00', 1),
(3, 'Z01', 'C03', '2025-11-08', NULL, 0),
(4, 'Z04', 'C04', '2025-09-15', '2025-11-11 09:00:00', 1),
(5, 'Z04', 'C05', '2025-11-01', '2025-11-11 10:00:00', 1);

-- THÊM BẢNG Harvests
INSERT INTO Harvests VALUES
(1, 1, '2025-12-30', 250.0, 'A'),
(2, 4, '2025-12-10', 380.5, 'A'),
(3, 6, '2025-11-25', 65.0, 'B'),
(4, 2, '2025-12-20', 0.0, 'C');

-- Tăng 10% expected_yield cho C01
UPDATE Crops
SET expected_yield = expected_yield * 1.10
WHERE crop_id = 'C01';

-- Cập nhật status Z03 -> Maintenance
UPDATE Zones
SET status = 'Maintenance'
WHERE zone_id = 'Z03';

-- Xóa harvest có yield = 0 hoặc grade = 'C'
DELETE FROM Harvests
WHERE actual_yield = 0 OR quality_grade = 'C';

-- Thêm cột fertilizer_type
ALTER TABLE Crops
ADD fertilizer_type VARCHAR(50);


-- Liệt kê các cây có thời gian sinh trưởng < 50 ngày
SELECT *
FROM Crops
WHERE growth_time_days < 50;


-- Lấy zone_name, area của khu vực có ánh sáng 'Full Sun'
SELECT zone_name, area_square_meters
FROM Zones
WHERE light_condition = 'Full Sun';


-- Danh sách cây (tên + sản lượng), sắp xếp giảm dần theo yield
SELECT crop_name, expected_yield
FROM Crops
ORDER BY expected_yield DESC;


-- Lấy 3 nhật ký trồng mới nhất
SELECT *
FROM Planting_Logs
ORDER BY planting_date DESC
LIMIT 3;


-- Lấy zone_name, status (bỏ qua dòng đầu, lấy 2 dòng tiếp)
SELECT zone_name, status
FROM Zones
LIMIT 2 OFFSET 1;


-- Cập nhật last_watered = thời gian hiện tại cho log tự động
UPDATE Planting_Logs
SET last_watered = NOW()
WHERE is_automated = 1;


-- Chuyển toàn bộ crop_name thành chữ in hoa
UPDATE Crops
SET crop_name = UPPER(crop_name);


-- Xóa Zones có status = 'Maintenance' (xử lý FK)
DELETE FROM Harvests
WHERE log_id IN (
    SELECT log_id FROM Planting_Logs
    WHERE zone_id IN (
        SELECT zone_id FROM Zones WHERE status = 'Maintenance'
    )
);
DELETE FROM Planting_Logs
WHERE zone_id IN (
    SELECT zone_id FROM Zones WHERE status = 'Maintenance'
);
DELETE FROM Zones
WHERE status = 'Maintenance';

-- Hiển thị log_id, zone_name, crop_name, planting_date của các khu vực đang 'Occupied'
SELECT pl.log_id, z.zone_name, c.crop_name, pl.planting_date
FROM Planting_Logs pl
JOIN Zones z ON pl.zone_id = z.zone_id
JOIN Crops c ON pl.crop_id = c.crop_id
WHERE z.status = 'Occupied';

-- Liệt kê tất cả khu vực và số lần đã trồng (kể cả chưa từng trồng)
SELECT z.zone_name, COUNT(pl.log_id) AS total_plantings
FROM Zones z
LEFT JOIN Planting_Logs pl ON z.zone_id = pl.zone_id
GROUP BY z.zone_id, z.zone_name;

-- Tổng sản lượng thực tế theo từng loại cây
SELECT c.crop_name, SUM(h.actual_yield) AS total_actual_yield
FROM Crops c
JOIN Planting_Logs pl ON c.crop_id = pl.crop_id
JOIN Harvests h ON pl.log_id = h.log_id
GROUP BY c.crop_id, c.crop_name;

-- Thống kê số loại cây khác nhau mỗi khu vực đã trồng (>=2)
SELECT z.zone_name, COUNT(DISTINCT pl.crop_id) AS total_crops
FROM Zones z
JOIN Planting_Logs pl ON z.zone_id = pl.zone_id
GROUP BY z.zone_id, z.zone_name
HAVING COUNT(DISTINCT pl.crop_id) >= 2;


-- Tìm cây có expected_yield > trung bình toàn hệ thống
SELECT crop_name, expected_yield
FROM Crops
WHERE expected_yield > (
    SELECT AVG(expected_yield) FROM Crops
);

-- Hiển thị zone_name đang trồng "Cà chua Cherry"
SELECT DISTINCT z.zone_name
FROM Zones z
JOIN Planting_Logs pl ON z.zone_id = pl.zone_id
JOIN Crops c ON pl.crop_id = c.crop_id
WHERE c.crop_name = 'Cà chua Cherry';


-- Tính % hiệu quả = actual_yield / (expected_yield * area) * 100
SELECT pl.log_id, z.zone_name, c.crop_name, h.actual_yield, (c.expected_yield * z.area_square_meters) AS expected_total_yield, ROUND((h.actual_yield / (c.expected_yield * z.area_square_meters)) * 100, 2) AS efficiency_percent
FROM Harvests h
JOIN Planting_Logs pl ON h.log_id = pl.log_id
JOIN Zones z ON pl.zone_id = z.zone_id
JOIN Crops c ON pl.crop_id = c.crop_id;