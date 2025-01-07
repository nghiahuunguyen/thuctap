
DROP TABLE IF EXISTS Providers;
CREATE TABLE Providers (
    provider_id INTEGER PRIMARY KEY AUTOINCREMENT,                     -- Mã định danh duy nhất của nhà cung cấp
    provider_name VARCHAR(100) NOT NULL,                                 -- Tên của nhà cung cấp
    contact_info VARCHAR(255),                                           -- Thông tin liên hệ của nhà cung cấp
    website VARCHAR(255),                                               -- Trang web của nhà cung cấp
    provider_type VARCHAR(50) NOT NULL CHECK(provider_type IN ('Cloud', 'SaaS', 'Hardware')), -- Loại nhà cung cấp
    account_manager_name VARCHAR(100),                                   -- Tên quản lý tài khoản
    account_manager_email VARCHAR(100),                                  -- Email của quản lý tài khoản
    contract_start_date DATE NOT NULL,                                   -- Ngày bắt đầu hợp đồng
    contract_end_date DATE NOT NULL,                                     -- Ngày kết thúc hợp đồng
    payment_terms VARCHAR(50) NOT NULL,                                  -- Điều khoản thanh toán
    status VARCHAR(50) DEFAULT 'Active' CHECK(status IN ('Active', 'Inactive', 'Suspended')), -- Trạng thái nhà cung cấp
    -- Ràng buộc: ngày kết thúc lớn hơn ngày bắt đầu
    CHECK (contract_end_date > contract_start_date), 
    -- Ràng buộc: kiểm tra định dạng email
    CHECK (account_manager_email LIKE '%@%.%')
);

DROP TABLE IF EXISTS Projects;
CREATE TABLE Projects (
    project_id INTEGER PRIMARY KEY AUTOINCREMENT,                 -- Mã định danh duy nhất của dự án
    project_name TEXT NOT NULL,                                     -- Tên dự án
    description TEXT,                                               -- Mô tả chi tiết về dự án
    start_date DATE NOT NULL,                                        -- Ngày bắt đầu dự án
    end_date DATE,                                                  -- Ngày kết thúc dự án
    project_manager TEXT NOT NULL,                                  -- Tên quản lý dự án
    department TEXT NOT NULL,                                       -- Phòng ban chịu trách nhiệm
    priority TEXT CHECK(priority IN ('Low', 'Medium', 'High', 'Critical')) DEFAULT 'Medium', -- Mức độ ưu tiên
    status TEXT CHECK(status IN ('Planning', 'In Progress', 'Completed', 'On Hold', 'Cancelled')) DEFAULT 'Planning', -- Trạng thái của dự án
    budget_allocated DECIMAL(15, 2) NOT NULL DEFAULT 0.00,           -- Ngân sách được phân bổ
    client_name TEXT,                                               -- Tên khách hàng
    CHECK (end_date > start_date),                                  -- Ràng buộc: ngày kết thúc lớn hơn ngày bắt đầu
    CHECK (budget_allocated >= 0)                                    -- Kiểm tra ngân sách phải >= 0
);

DROP TABLE IF EXISTS Resources;
CREATE TABLE Resources (
    resource_id INTEGER PRIMARY KEY AUTOINCREMENT,                       -- Mã định danh duy nhất của tài nguyên
    resource_name VARCHAR(100) NOT NULL,                                   -- Tên của tài nguyên
    fk_provider_id INTEGER NOT NULL,                                       -- Khóa ngoại liên kết với bảng nhà cung cấp
    resource_type VARCHAR(50) NOT NULL,                                     -- Loại tài nguyên
    configuration TEXT,                                                    -- Cấu hình chi tiết của tài nguyên
    subscription_type VARCHAR(50) NOT NULL CHECK(subscription_type IN ('Monthly', 'Yearly')), -- Loại hình đăng ký
    unit_price DECIMAL(10, 2) NOT NULL DEFAULT 0.00 CHECK(unit_price >= 0), -- Giá trên mỗi đơn vị
    recommended_capacity INT NOT NULL DEFAULT 1 CHECK(recommended_capacity > 0), -- Dung lượng khuyến nghị
    efficiency_rating DECIMAL(3, 2) NOT NULL CHECK(efficiency_rating BETWEEN 0.00 AND 1.00), -- Chỉ số hiệu suất
    -- Ràng buộc kiểm tra giá trị cho efficiency_rating
    CHECK (efficiency_rating BETWEEN 0.00 AND 1.00),
    -- Ràng buộc kiểm tra unit_price phải >= 0
    CHECK (unit_price >= 0),
    -- Ràng buộc kiểm tra recommended_capacity phải > 0
    CHECK (recommended_capacity > 0),
    -- Khóa ngoại liên kết với bảng Providers
    FOREIGN KEY (fk_provider_id) REFERENCES Providers(provider_id)
);

DROP TABLE IF EXISTS Costs;
CREATE TABLE Costs (
    cost_id INTEGER PRIMARY KEY AUTOINCREMENT,
    fk_project_id INTEGER NOT NULL,
    fk_resource_id INTEGER NOT NULL,
    cost_amount DECIMAL(15, 2) NOT NULL CHECK (cost_amount > 0),
    cost_date DATE NOT NULL,
    cost_type TEXT NOT NULL CHECK (cost_type IN ('Operational', 'Subscription')),
    billing_cycle TEXT NOT NULL CHECK (billing_cycle IN ('Monthly', 'Quarterly', 'Annually')),
    payment_method TEXT NOT NULL CHECK (payment_method IN ('Credit Card', 'Bank Transfer')),
    invoice_number TEXT UNIQUE NOT NULL,
    notes TEXT,
    -- Ràng buộc khóa ngoại
    FOREIGN KEY (fk_project_id) REFERENCES Projects(project_id),
    FOREIGN KEY (fk_resource_id) REFERENCES Resources(resource_id),
    CHECK (cost_amount > 0)
);

DROP TABLE IF EXISTS Cost_Alerts;
CREATE TABLE Cost_Alerts (
    alert_id INTEGER PRIMARY KEY AUTOINCREMENT,                         -- Mã định danh duy nhất của cảnh báo chi phí
    fk_project_id INTEGER,                                              -- Khóa ngoại liên kết với bảng dự án
    fk_resource_id INTEGER,                                             -- Khóa ngoại liên kết với bảng tài nguyên
    alert_type TEXT NOT NULL CHECK (alert_type IN ('Budget Exceed', 'Unusual Spending')),  -- Loại cảnh báo
    threshold_amount DECIMAL(15, 2) CHECK (threshold_amount > 0),       -- Ngưỡng cảnh báo chi phí
    current_amount DECIMAL(15, 2) CHECK (current_amount >= 0),          -- Giá trị chi phí hiện tại
    alert_date DATETIME NOT NULL,                                       -- Ngày giờ tạo cảnh báo
    status TEXT DEFAULT 'Active' CHECK (status IN ('Active', 'Resolved', 'Ignored')),  -- Trạng thái của cảnh báo
    notification_sent BOOLEAN DEFAULT FALSE,                            -- Đã gửi thông báo chưa
    -- Ràng buộc khóa ngoại
    FOREIGN KEY (fk_project_id) REFERENCES Projects(project_id),
    FOREIGN KEY (fk_resource_id) REFERENCES Resources(resource_id),
    CHECK (threshold_amount > 0),                                       -- Ràng buộc: threshold_amount > 0
    CHECK (current_amount >= 0)                                         -- Ràng buộc: current_amount >= 0
);

DROP TABLE IF EXISTS Resource_Utilization;
CREATE TABLE Resource_Utilization (
    utilization_id INTEGER PRIMARY KEY AUTOINCREMENT,                  -- Mã định danh duy nhất của bản ghi sử dụng tài nguyên
    fk_resource_id INTEGER NOT NULL,                                    -- Khóa ngoại liên kết với bảng tài nguyên
    fk_project_id INTEGER NOT NULL,                                     -- Khóa ngoại liên kết với bảng dự án
    record_date DATE NOT NULL,                                           -- Ngày ghi nhận sử dụng tài nguyên
    cpu_utilization DECIMAL(5, 2) NOT NULL CHECK (cpu_utilization >= 0 AND cpu_utilization <= 100),  -- Tỷ lệ sử dụng CPU (%)
    memory_utilization DECIMAL(5, 2) NOT NULL CHECK (memory_utilization >= 0 AND memory_utilization <= 100),  -- Tỷ lệ sử dụng bộ nhớ (%)
    storage_utilization DECIMAL(5, 2) NOT NULL CHECK (storage_utilization >= 0 AND storage_utilization <= 100),  -- Tỷ lệ sử dụng bộ nhớ lưu trữ (%)
    network_traffic DECIMAL(15, 2) NOT NULL,                             -- Lượng dữ liệu truyền qua mạng
    active_users INT NOT NULL DEFAULT 0,                                 -- Số người dùng hoạt động
    performance_score DECIMAL(4, 2) NOT NULL CHECK (performance_score >= 0 AND performance_score <= 10), -- Điểm hiệu suất tài nguyên (0 - 10)
    -- Ràng buộc khóa ngoại
    FOREIGN KEY (fk_resource_id) REFERENCES Resources(resource_id),
    FOREIGN KEY (fk_project_id) REFERENCES Projects(project_id),
    CHECK (cpu_utilization >= 0 AND cpu_utilization <= 100),            -- Ràng buộc kiểm tra giá trị CPU
    CHECK (memory_utilization >= 0 AND memory_utilization <= 100),      -- Ràng buộc kiểm tra giá trị Memory
    CHECK (storage_utilization >= 0 AND storage_utilization <= 100)     -- Ràng buộc kiểm tra giá trị Storage
);

DROP TABLE IF EXISTS User;
CREATE TABLE User (
    user_id INTEGER PRIMARY KEY AUTOINCREMENT,                            -- Mã định danh duy nhất của người dùng
    username VARCHAR(50) UNIQUE NOT NULL,                                  -- Tên đăng nhập của người dùng
    password_hash VARCHAR(255) NOT NULL,                                   -- Mã hóa mật khẩu
    email VARCHAR(100) UNIQUE NOT NULL,                                    -- Địa chỉ email của người dùng
    full_name VARCHAR(100) NOT NULL,                                       -- Họ và tên của người dùng
    role TEXT CHECK(role IN ('Admin', 'Project Manager', 'User')) NOT NULL, -- Vai trò của người dùng
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,                          -- Thời gian tạo tài khoản
    last_login DATETIME,                                                   -- Thời gian đăng nhập gần nhất
    status TEXT CHECK(status IN ('Active', 'Inactive', 'Suspended')) DEFAULT 'Active', -- Trạng thái của tài khoản
    -- Ràng buộc kiểm tra tên đăng nhập
    CHECK (username NOT LIKE '%[^A-Za-z0-9_]%'),                            -- Ràng buộc kiểm tra tính hợp lệ của tên đăng nhập (chỉ cho phép ký tự chữ, số và dấu gạch dưới)
    CHECK (email LIKE '%@%.%')                                              -- Ràng buộc kiểm tra định dạng email hợp lệ
);

DROP TABLE IF EXISTS User_Project_Access;
CREATE TABLE User_Project_Access (
    access_id INTEGER PRIMARY KEY AUTOINCREMENT,                            -- Mã định danh duy nhất cho quyền truy cập
    fk_user_id INTEGER NOT NULL,                                             -- ID người dùng
    fk_project_id INTEGER NOT NULL,                                          -- ID dự án
    access_level TEXT CHECK(access_level IN ('Read-Only', 'Read-Write', 'Admin')) NOT NULL, -- Cấp độ truy cập vào dự án
    granted_by INTEGER NOT NULL,                                             -- ID của người cấp quyền truy cập
    granted_at DATETIME DEFAULT CURRENT_TIMESTAMP,                           -- Thời gian cấp quyền
    expires_at DATETIME,                                                     -- Thời gian hết hạn quyền truy cập
    status TEXT CHECK(status IN ('Active', 'Expired', 'Revoked')) DEFAULT 'Active', -- Trạng thái quyền truy cập
    -- Ràng buộc khóa ngoại
    FOREIGN KEY (fk_user_id) REFERENCES User(user_id),
    FOREIGN KEY (fk_project_id) REFERENCES Projects(project_id),
    CHECK (expires_at IS NULL OR expires_at > granted_at)                    -- Ràng buộc: expires_at phải lớn hơn granted_at nếu có giá trị
);



INSERT INTO Providers (provider_name, contact_info, website, provider_type, account_manager_name, account_manager_email, contract_start_date, contract_end_date, payment_terms, status)
VALUES
('CloudCorp', '123 Cloud Street, NY', 'http://cloudcorp.com', 'Cloud', 'John Doe', 'johndoe@cloudcorp.com', '2023-01-01', '2025-01-01', 'Net 30', 'Active'),
('SaaSGlobal', '456 SaaS Avenue, CA', 'http://saasglobal.com', 'SaaS', 'Jane Smith', 'janesmith@saasglobal.com', '2022-05-15', '2024-05-15', 'Net 60', 'Active'),
('HardwarePro', '789 Hardware Rd, TX', 'http://hardwarepro.com', 'Hardware', 'Mike Johnson', 'mikejohnson@hardwarepro.com', '2021-10-01', '2023-10-01', 'Net 45', 'Inactive'),
('TechSolutions', '101 Tech Blvd, FL', 'http://techsolutions.com', 'Cloud', 'Emily Davis', 'emilydavis@techsolutions.com', '2024-01-01', '2026-01-01', 'Net 30', 'Active'),
('SoftwaresInc', '102 Software Lane, CA', 'http://softwaresinc.com', 'SaaS', 'Robert Brown', 'robertbrown@softwaresinc.com', '2023-02-10', '2025-02-10', 'Net 90', 'Suspended'),
('DataSystems', '203 Data St, TX', 'http://datasystems.com', 'Cloud', 'Alice Wilson', 'alicewilson@datasystems.com', '2022-07-15', '2024-07-15', 'Net 60', 'Active'),
('QuantumTech', '304 Quantum Ave, IL', 'http://quantumtech.com', 'Hardware', 'David Clark', 'davidclark@quantumtech.com', '2023-06-01', '2025-06-01', 'Net 45', 'Active'),
('NextGenCloud', '505 Nextgen Blvd, NY', 'http://nextgencloud.com', 'Cloud', 'Sarah Lewis', 'sarahlewis@nextgencloud.com', '2022-11-10', '2024-11-10', 'Net 30', 'Active'),
('GlobalSaaS', '606 Global Rd, CA', 'http://globalsaas.com', 'SaaS', 'William Harris', 'williamharris@globalsaas.com', '2023-04-05', '2025-04-05', 'Net 90', 'Suspended'),
('FutureTech', '707 Future St, WA', 'http://futuretech.com', 'Hardware', 'Sophia Martinez', 'sophiamartinez@futuretech.com', '2021-12-20', '2023-12-20', 'Net 45', 'Inactive'),
('AlphaCloud', '901 Alpha Rd, TX', 'http://alphacloud.com', 'Cloud', 'Chris Walker', 'chriswalker@alphacloud.com', '2023-03-01', '2025-03-01', 'Net 30', 'Active'),
('BetaSaaS', '120 Beta Lane, NY', 'http://betasaas.com', 'SaaS', 'Patricia Allen', 'patriciaallen@betasaas.com', '2022-06-15', '2024-06-15', 'Net 60', 'Active'),
('GammaHardware', '456 Gamma Blvd, CA', 'http://gammahardware.com', 'Hardware', 'Richard Adams', 'richardadams@gammahardware.com', '2021-09-10', '2023-09-10', 'Net 45', 'Inactive'),
('DeltaSolutions', '789 Delta Ave, IL', 'http://deltasolutions.com', 'Cloud', 'Laura White', 'laurawhite@deltasolutions.com', '2024-02-01', '2026-02-01', 'Net 30', 'Active'),
('EpsilonSoft', '345 Epsilon Rd, TX', 'http://epsilonsoft.com', 'SaaS', 'Daniel Harris', 'danielharris@epsilonsoft.com', '2023-05-20', '2025-05-20', 'Net 90', 'Suspended'),
('ZetaData', '678 Zeta St, FL', 'http://zetadata.com', 'Cloud', 'Nancy Scott', 'nancyscott@zetadata.com', '2022-08-10', '2024-08-10', 'Net 60', 'Active'),
('EtaTech', '901 Eta Blvd, WA', 'http://etatech.com', 'Hardware', 'Gary Moore', 'garymoore@etatech.com', '2023-07-01', '2025-07-01', 'Net 45', 'Active'),
('ThetaCloud', '234 Theta Rd, NY', 'http://thetacloud.com', 'Cloud', 'Anna Garcia', 'annagarcia@thetacloud.com', '2022-10-15', '2024-10-15', 'Net 30', 'Active'),
('IotaSaaS', '567 Iota Lane, CA', 'http://iotasaas.com', 'SaaS', 'Robert Rodriguez', 'robertrodriguez@iotasaas.com', '2023-06-10', '2025-06-10', 'Net 90', 'Suspended'),
('KappaHardware', '890 Kappa Blvd, IL', 'http://kappahardware.com', 'Hardware', 'Linda Martinez', 'lindamartinez@kappahardware.com', '2021-11-01', '2023-11-01', 'Net 45', 'Inactive'),
('LambdaSolutions', '345 Lambda Ave, TX', 'http://lambdasolutions.com', 'Cloud', 'Matthew Walker', 'matthewwalker@lambdasolutions.com', '2024-03-01', '2026-03-01', 'Net 30', 'Active'),
('MuSoft', '678 Mu Rd, CA', 'http://musoft.com', 'SaaS', 'Emily Hernandez', 'emilyhernandez@musoft.com', '2023-07-15', '2025-07-15', 'Net 60', 'Active'),
('NuData', '901 Nu Blvd, FL', 'http://nudata.com', 'Cloud', 'Barbara Davis', 'barbaradavis@nudata.com', '2022-09-10', '2024-09-10', 'Net 45', 'Active'),
('XiTech', '123 Xi Lane, NY', 'http://xitech.com', 'Hardware', 'Kevin Jackson', 'kevinjackson@xitech.com', '2023-08-20', '2025-08-20', 'Net 90', 'Suspended'),
('OmicronCloud', '345 Omicron St, IL', 'http://omicroncloud.com', 'Cloud', 'Karen Lewis', 'karenlewis@omicroncloud.com', '2022-11-01', '2024-11-01', 'Net 30', 'Active'),
('PiSaaS', '678 Pi Rd, TX', 'http://pisaas.com', 'SaaS', 'David Lee', 'davidlee@pisaas.com', '2023-09-10', '2025-09-10', 'Net 60', 'Active'),
('RhoHardware', '901 Rho Ave, CA', 'http://rhohardware.com', 'Hardware', 'James Gonzalez', 'jamesgonzalez@rhohardware.com', '2021-12-01', '2023-12-01', 'Net 45', 'Inactive'),
('SigmaSolutions', '123 Sigma Blvd, FL', 'http://sigmasolutions.com', 'Cloud', 'Mary Brown', 'marybrown@sigmasolutions.com', '2024-04-01', '2026-04-01', 'Net 30', 'Active'),
('TauSoft', '456 Tau Rd, TX', 'http://tausoft.com', 'SaaS', 'Michael Thompson', 'michaelthompson@tausoft.com', '2023-08-15', '2025-08-15', 'Net 90', 'Suspended'),
('UpsilonData', '789 Upsilon Lane, NY', 'http://upsilondata.com', 'Cloud', 'Elizabeth Wilson', 'elizabethwilson@upsilondata.com', '2022-10-10', '2024-10-10', 'Net 60', 'Active'),
('PhiTech', '123 Phi Ave, CA', 'http://phitech.com', 'Hardware', 'William Young', 'williamyoung@phitech.com', '2023-10-01', '2025-10-01', 'Net 45', 'Active'),
('ChiCloud', '345 Chi Blvd, TX', 'http://chicloud.com', 'Cloud', 'Linda Martinez', 'lindamartinez@chicloud.com', '2022-12-10', '2024-12-10', 'Net 30', 'Active'),
('PsiSaaS', '567 Psi Rd, IL', 'http://psisaas.com', 'SaaS', 'Jeffrey Harris', 'jeffreyharris@psisaas.com', '2023-11-20', '2025-11-20', 'Net 60', 'Active'),
('OmegaHardware', '789 Omega Lane, FL', 'http://omegahardware.com', 'Hardware', 'Sandra Martin', 'sandramartin@omegahardware.com', '2021-12-15', '2023-12-15', 'Net 45', 'Inactive'),
('AlphaOmegaSolutions', '123 AlphaOmega Blvd, CA', 'http://alphaomegasolutions.com', 'Cloud', 'Rachel Adams', 'racheladams@alphaomegasolutions.com', '2024-05-01', '2026-05-01', 'Net 30', 'Active');


INSERT INTO Projects (project_name, description, start_date, end_date, project_manager, department, priority, status, budget_allocated, client_name)
VALUES
('CloudMigration', 'Migrate data to the cloud for better scalability.', '2024-01-01', '2025-01-01', 'John Doe', 'IT', 'High', 'In Progress', 50000.00, 'ABC Corp'),
('SaaS Integration', 'Integrate SaaS solutions into company workflows.', '2024-02-01', '2025-02-01', 'Jane Smith', 'IT', 'Medium', 'Planning', 30000.00, 'XYZ Ltd'),
('Hardware Setup', 'Setup hardware infrastructure for the new office.', '2024-03-01', '2025-03-01', 'Michael Lee', 'Operations', 'Low', 'Completed', 20000.00, 'LMN Group'),
('Data Security', 'Enhance data security measures and protocols.', '2024-04-01', '2025-04-01', 'Sarah Wong', 'Security', 'Critical', 'In Progress', 70000.00, 'PQR Corp'),
('Network Optimization', 'Improve network performance and reduce latency.', '2024-05-01', '2025-05-01', 'David Clark', 'Network', 'High', 'On Hold', 40000.00, 'DEF Solutions'),
('Software Development', 'Develop internal software to streamline operations.', '2024-06-01', '2025-06-01', 'Emily Davis', 'Development', 'Medium', 'In Progress', 60000.00, 'MNO Inc'),
('Cloud Infrastructure', 'Build cloud infrastructure for a scalable platform.', '2024-07-01', '2025-07-01', 'Robert Brown', 'Cloud', 'Critical', 'Planning', 80000.00, 'RST Ltd'),
('SaaS Optimization', 'Optimize the existing SaaS application for better performance.', '2024-08-01', '2025-08-01', 'Linda Green', 'Development', 'Low', 'Completed', 25000.00, 'JKL Tech'),
('AI Implementation', 'Implement AI solutions for customer analytics.', '2024-09-01', '2025-09-01', 'Sophia Martinez', 'AI', 'High', 'In Progress', 75000.00, 'CDE Analytics'),
('Digital Transformation', 'Transition company processes to digital platforms.', '2024-10-01', '2025-10-01', 'William Harris', 'IT', 'Critical', 'Planning', 90000.00, 'OPQ Innovations'),
('Employee Training', 'Conduct training sessions for new software tools.', '2024-11-01', '2025-11-01', 'Alice Wilson', 'HR', 'Medium', 'On Hold', 15000.00, 'TUV Systems'),
('Data Migration', 'Migrate legacy database to new platform.', '2024-12-01', '2025-12-01', 'James Nguyen', 'Database', 'High', 'In Progress', 50000.00, 'GHK Technologies'),
('Mobile App Development', 'Create a mobile app for customer engagement.', '2025-01-01', '2025-12-31', 'David Young', 'Development', 'Critical', 'In Progress', 120000.00, 'WXY Enterprises'),
('Cybersecurity Audit', 'Conduct a comprehensive cybersecurity audit.', '2024-11-15', '2025-11-15', 'Mary Zhang', 'Security', 'High', 'In Progress', 55000.00, 'UVW Corp'),
('IoT Deployment', 'Deploy IoT devices for real-time monitoring.', '2024-12-15', '2025-12-15', 'Tom Brown', 'IoT', 'Medium', 'Planning', 35000.00, 'NOP Sensors'),
('Green Computing', 'Initiate eco-friendly computing solutions.', '2024-10-15', '2025-10-15', 'Karen White', 'Sustainability', 'Low', 'Completed', 30000.00, 'EFG GreenTech'),
('Server Upgrade', 'Upgrade servers for better performance.', '2024-12-10', '2025-12-10', 'Nathan Black', 'Infrastructure', 'Medium', 'On Hold', 40000.00, 'HIJ Solutions'),
('Customer Portal', 'Develop a customer portal for self-service options.', '2024-08-15', '2025-08-15', 'Olivia Lee', 'Development', 'Critical', 'In Progress', 85000.00, 'ABC Corp'),
('AR Integration', 'Integrate AR features into existing mobile app.', '2024-07-15', '2025-07-15', 'Ethan Wright', 'Development', 'High', 'Planning', 60000.00, 'XYZ Ltd'),
('Compliance Review', 'Ensure all processes comply with new regulations.', '2024-06-15', '2025-06-15', 'Isabella Green', 'Legal', 'Medium', 'In Progress', 45000.00, 'LMN Group'),
('Data Analytics', 'Set up data analytics pipeline.', '2024-05-15', '2025-05-15', 'Jack Walker', 'Analytics', 'High', 'On Hold', 65000.00, 'PQR Corp'),
('E-commerce Platform', 'Develop an e-commerce platform for new products.', '2024-04-15', '2025-04-15', 'Emma King', 'Development', 'Critical', 'In Progress', 100000.00, 'DEF Solutions'),
('Backup Systems', 'Create reliable backup systems for disaster recovery.', '2024-03-15', '2025-03-15', 'Lucas Gray', 'Infrastructure', 'High', 'Planning', 50000.00, 'MNO Inc');


INSERT INTO Resources (resource_name, fk_provider_id, resource_type, configuration, subscription_type, unit_price, recommended_capacity, efficiency_rating)
VALUES
('Cloud Storage', 1, 'Storage', '50 TB', 'Monthly', 1000.00, 50, 0.95),
('SaaS License', 2, 'Software', 'Team Collaboration', 'Yearly', 200.00, 100, 0.90),  -- changed 'Annual' to 'Yearly'
('Hardware Servers', 3, 'Hardware', 'Rackmount Servers', 'Yearly', 3000.00, 20, 0.85),  -- changed 'Annual' to 'Yearly'
('Firewall Protection', 1, 'Security', 'Advanced Firewall', 'Monthly', 500.00, 10, 0.98),
('Virtual Machines', 2, 'Cloud', 'Virtual Machine for Developers', 'Monthly', 1500.00, 30, 0.92),
('Data Backup', 3, 'Storage', 'Cloud Backup Services', 'Yearly', 800.00, 40, 0.91),  -- changed 'Annual' to 'Yearly'
('Server Hosting', 1, 'Hosting', 'Dedicated Server Hosting', 'Yearly', 1200.00, 25, 0.93),
('SaaS Management Tool', 2, 'Software', 'Project Management', 'Monthly', 350.00, 60, 0.89),
('Cloud Database', 1, 'Database', 'Managed SQL Database', 'Monthly', 2000.00, 10, 0.96),
('CRM Software', 2, 'Software', 'Customer Relationship Management', 'Yearly', 500.00, 50, 0.88),
('Networking Equipment', 3, 'Hardware', 'High-Speed Routers', 'Yearly', 2500.00, 15, 0.87),
('Cloud Analytics', 1, 'Analytics', 'Real-Time Analytics Platform', 'Monthly', 1800.00, 20, 0.94),
('Development Tools', 2, 'Software', 'Integrated Development Environment', 'Monthly', 400.00, 30, 0.89),
('AI Platform', 3, 'AI', 'Machine Learning Platform', 'Yearly', 5000.00, 8, 0.93),
('Load Balancer', 1, 'Hosting', 'Cloud Load Balancer', 'Monthly', 1200.00, 50, 0.92),
('SaaS HR Tool', 2, 'Software', 'Human Resource Management', 'Yearly', 600.00, 80, 0.86),
('Storage Gateway', 3, 'Storage', 'Cloud Storage Gateway', 'Yearly', 1000.00, 40, 0.90),
('Collaboration Suite', 2, 'Software', 'Team Collaboration Suite', 'Monthly', 300.00, 100, 0.91),
('Server Monitoring', 1, 'Monitoring', 'Server Health Monitoring Tool', 'Monthly', 700.00, 25, 0.97),
('Cloud CDN', 1, 'Hosting', 'Content Delivery Network', 'Yearly', 1500.00, 100, 0.94),
('Firewall Upgrade', 3, 'Security', 'Next-Gen Firewall', 'Yearly', 1000.00, 15, 0.96),
('Mobile App Backend', 2, 'Software', 'Backend-as-a-Service', 'Monthly', 800.00, 40, 0.92),
('Data Replication', 3, 'Storage', 'Real-Time Data Replication', 'Yearly', 1200.00, 30, 0.91),
('AI API Access', 1, 'AI', 'API for Machine Learning Models', 'Monthly', 600.00, 25, 0.93);


INSERT INTO Costs (fk_project_id, fk_resource_id, cost_amount, cost_date, cost_type, billing_cycle, payment_method, invoice_number, notes)
VALUES
(1, 1, 1000.00, '2024-01-15', 'Subscription', 'Monthly', 'Credit Card', 'INV1234', 'Cloud Storage for January'),
(2, 2, 500.00, '2024-02-10', 'Subscription', 'Quarterly', 'Bank Transfer', 'INV5678', 'SaaS License for Q1'),
(3, 3, 3000.00, '2024-03-05', 'Subscription', 'Annually', 'Credit Card', 'INV9101', 'Hardware Servers for 2024'),
(4, 4, 500.00, '2024-04-15', 'Operational', 'Monthly', 'Bank Transfer', 'INV1122', 'Firewall Protection for April'),
(5, 5, 1500.00, '2024-05-01', 'Subscription', 'Monthly', 'Credit Card', 'INV3344', 'Virtual Machines for May'),
(6, 6, 800.00, '2024-06-10', 'Subscription', 'Annually', 'Bank Transfer', 'INV5566', 'Data Backup Service for 2024'),
(7, 7, 1200.00, '2024-07-01', 'Subscription', 'Annually', 'Credit Card', 'INV7788', 'Server Hosting for 2024'),
(8, 8, 350.00, '2024-08-20', 'Operational', 'Monthly', 'Bank Transfer', 'INV9900', 'SaaS Management Tool for August'),
(2, 3, 2000.00, '2024-02-20', 'Subscription', 'Monthly', 'Credit Card', 'INV1236', 'Hardware Servers for February'),
(3, 4, 750.00, '2024-03-15', 'Subscription', 'Quarterly', 'Bank Transfer', 'INV5680', 'Firewall Protection for Q1'),
(4, 5, 3000.00, '2024-04-10', 'Subscription', 'Annually', 'Credit Card', 'INV9103', 'Virtual Machines for 2024'),
(5, 6, 650.00, '2024-05-05', 'Operational', 'Monthly', 'Bank Transfer', 'INV1124', 'Data Backup Service for May'),
(6, 7, 2000.00, '2024-06-20', 'Subscription', 'Monthly', 'Credit Card', 'INV3346', 'Server Hosting for 2024'),
(7, 8, 400.00, '2024-07-01', 'Operational', 'Monthly', 'Bank Transfer', 'INV5568', 'SaaS Management Tool for July'),
(8, 1, 1200.00, '2024-08-05', 'Subscription', 'Monthly', 'Credit Card', 'INV7789', 'Cloud Storage for August'),
(1, 2, 450.00, '2024-09-10', 'Subscription', 'Quarterly', 'Bank Transfer', 'INV9902', 'SaaS License for Q3'),
(2, 6, 950.00, '2024-03-25', 'Subscription', 'Annually', 'Credit Card', 'INV1240', 'Data Backup Service for 2024'),
(3, 1, 1500.00, '2024-04-15', 'Subscription', 'Monthly', 'Bank Transfer', 'INV5682', 'Cloud Storage for April'),
(4, 2, 600.00, '2024-05-05', 'Subscription', 'Quarterly', 'Credit Card', 'INV9105', 'SaaS License for Q2'),
(5, 4, 800.00, '2024-06-01', 'Operational', 'Monthly', 'Bank Transfer', 'INV1126', 'Firewall Protection for June'),
(6, 3, 3500.00, '2024-07-10', 'Subscription', 'Annually', 'Credit Card', 'INV3348', 'Hardware Servers for 2024'),
(7, 5, 1200.00, '2024-08-05', 'Subscription', 'Monthly', 'Bank Transfer', 'INV5567', 'Virtual Machines for August'),
(8, 7, 2200.00, '2024-09-01', 'Operational', 'Annually', 'Credit Card', 'INV7790', 'Server Hosting for 2024'),
(1, 8, 400.00, '2024-10-20', 'Subscription', 'Monthly', 'Bank Transfer', 'INV9905', 'SaaS Management Tool for October');


INSERT INTO Cost_Alerts (fk_project_id, fk_resource_id, alert_type, threshold_amount, current_amount, alert_date, status, notification_sent)
VALUES
(1, 1, 'Budget Exceed', 1200.00, 1500.00, '2024-01-20', 'Active', FALSE),
(2, 2, 'Unusual Spending', 700.00, 500.00, '2024-02-15', 'Resolved', TRUE),
(3, 3, 'Budget Exceed', 3000.00, 3200.00, '2024-03-10', 'Active', FALSE),
(4, 4, 'Unusual Spending', 600.00, 500.00, '2024-04-18', 'Resolved', TRUE),
(5, 5, 'Budget Exceed', 1700.00, 1500.00, '2024-05-05', 'Active', FALSE),
(6, 6, 'Unusual Spending', 900.00, 800.00, '2024-06-15', 'Resolved', TRUE),
(7, 7, 'Budget Exceed', 1300.00, 1200.00, '2024-07-05', 'Active', FALSE),
(8, 8, 'Unusual Spending', 400.00, 350.00, '2024-08-25', 'Resolved', TRUE),
(2, 3, 'Budget Exceed', 2500.00, 2000.00, '2024-02-25', 'Active', FALSE),
(3, 4, 'Unusual Spending', 1000.00, 750.00, '2024-03-20', 'Resolved', TRUE),
(4, 5, 'Budget Exceed', 3500.00, 3000.00, '2024-04-15', 'Active', FALSE),
(5, 6, 'Unusual Spending', 1000.00, 650.00, '2024-05-10', 'Resolved', TRUE),
(6, 7, 'Budget Exceed', 3000.00, 2000.00, '2024-06-25', 'Active', FALSE),
(7, 8, 'Unusual Spending', 500.00, 400.00, '2024-07-05', 'Resolved', TRUE),
(8, 1, 'Budget Exceed', 1300.00, 1200.00, '2024-08-10', 'Active', FALSE),
(1, 2, 'Unusual Spending', 500.00, 450.00, '2024-09-15', 'Resolved', TRUE),
(2, 6, 'Budget Exceed', 1100.00, 950.00, '2024-03-30', 'Active', FALSE),
(3, 1, 'Unusual Spending', 1600.00, 1500.00, '2024-04-20', 'Resolved', TRUE),
(4, 2, 'Budget Exceed', 800.00, 600.00, '2024-05-10', 'Active', FALSE),
(5, 4, 'Unusual Spending', 1000.00, 800.00, '2024-06-05', 'Resolved', TRUE),
(6, 3, 'Budget Exceed', 4000.00, 3500.00, '2024-07-15', 'Active', FALSE),
(7, 5, 'Unusual Spending', 1300.00, 1200.00, '2024-08-10', 'Resolved', TRUE),
(8, 7, 'Budget Exceed', 2500.00, 2200.00, '2024-09-10', 'Active', FALSE),
(1, 8, 'Unusual Spending', 500.00, 400.00, '2024-10-25', 'Resolved', TRUE);


INSERT INTO User (username, password_hash, email, full_name, role, created_at, last_login, status)
VALUES
('admin_user', 'hashed_password_1', 'admin@example.com', 'Admin User', 'Admin', '2024-01-01 10:00:00', '2024-12-18 08:00:00', 'Active'),
('pm_user', 'hashed_password_2', 'pm@example.com', 'Project Manager', 'Project Manager', '2024-01-05 09:00:00', '2024-12-18 08:30:00', 'Active'),
('regular_user', 'hashed_password_3', 'user@example.com', 'Regular User', 'User', '2024-02-01 12:00:00', '2024-12-17 07:30:00', 'Active'),
('john_doe', 'hashed_password_4', 'john@example.com', 'John Doe', 'User', '2024-03-15 15:00:00', '2024-12-18 09:00:00', 'Active'),
('jane_doe', 'hashed_password_5', 'jane@example.com', 'Jane Doe', 'Project Manager', '2024-04-10 08:00:00', '2024-12-17 09:30:00', 'Inactive'),
('alice_smith', 'hashed_password_6', 'alice@example.com', 'Alice Smith', 'User', '2024-05-05 13:00:00', '2024-12-16 10:00:00', 'Active'),
('bob_jones', 'hashed_password_7', 'bob@example.com', 'Bob Jones', 'Admin', '2024-06-01 11:00:00', '2024-12-17 11:00:00', 'Suspended'),
('charlie_brown', 'hashed_password_8', 'charlie@example.com', 'Charlie Brown', 'Project Manager', '2024-07-20 14:00:00', '2024-12-18 07:45:00', 'Active'),
('david_wilson', 'hashed_password_9', 'david@example.com', 'David Wilson', 'User', '2024-08-11 16:00:00', '2024-12-18 08:00:00', 'Active'),
('eva_martin', 'hashed_password_10', 'eva@example.com', 'Eva Martin', 'User', '2024-09-22 17:00:00', '2024-12-18 09:30:00', 'Active');


INSERT INTO Resource_Utilization (fk_resource_id, fk_project_id, record_date, cpu_utilization, memory_utilization, storage_utilization, network_traffic, active_users, performance_score)
VALUES
(1, 1, '2024-01-10', 75.00, 60.00, 85.00, 5000.00, 10, 8.5),
(2, 2, '2024-02-20', 55.00, 65.00, 90.00, 4500.00, 15, 7.8),
(3, 3, '2024-03-05', 85.00, 80.00, 70.00, 6000.00, 12, 9.2),
(4, 1, '2024-04-15', 60.00, 50.00, 80.00, 4000.00, 9, 8.0),
(5, 2, '2024-05-10', 70.00, 55.00, 75.00, 4200.00, 14, 8.7),
(6, 3, '2024-06-25', 65.00, 60.00, 90.00, 4700.00, 11, 8.3),
(7, 2, '2024-07-12', 80.00, 70.00, 65.00, 4800.00, 16, 8.9),
(8, 1, '2024-08-22', 50.00, 60.00, 85.00, 3900.00, 8, 7.5),
(9, 3, '2024-09-18', 75.00, 75.00, 80.00, 5100.00, 13, 9.0),
(10, 2, '2024-10-05', 60.00, 55.00, 90.00, 4600.00, 10, 8.1),
(2, 3, '2024-02-25', 65.00, 60.00, 85.00, 5100.00, 13, 8.2),
(3, 4, '2024-03-20', 80.00, 75.00, 80.00, 6000.00, 11, 8.6),
(4, 5, '2024-04-18', 60.00, 65.00, 70.00, 4900.00, 10, 7.9),
(5, 6, '2024-05-15', 75.00, 70.00, 80.00, 5000.00, 14, 8.4),
(6, 7, '2024-06-30', 70.00, 65.00, 75.00, 4600.00, 12, 8.1),
(7, 8, '2024-07-20', 80.00, 75.00, 70.00, 5200.00, 15, 8.8),
(8, 1, '2024-08-15', 60.00, 55.00, 85.00, 4500.00, 9, 7.6),
(9, 2, '2024-09-05', 70.00, 65.00, 80.00, 4800.00, 14, 8.3),
(10, 3, '2024-10-10', 75.00, 70.00, 90.00, 5300.00, 13, 8.7),
(11, 4, '2024-11-01', 55.00, 60.00, 80.00, 4600.00, 10, 7.8);


INSERT INTO User_Project_Access (fk_user_id, fk_project_id, access_level, granted_by, granted_at, expires_at, status)
VALUES
(1, 1, 'Admin', 1, '2024-01-01 10:00:00', '2024-12-31 23:59:59', 'Active'),
(2, 2, 'Read-Write', 1, '2024-01-05 09:00:00', '2024-06-30 23:59:59', 'Active'),
(3, 3, 'Read-Only', 2, '2024-02-15 14:00:00', '2024-12-31 23:59:59', 'Active'),
(4, 1, 'Read-Write', 2, '2024-03-01 08:00:00', '2024-06-30 23:59:59', 'Active'),
(5, 2, 'Read-Only', 1, '2024-04-10 10:00:00', '2024-12-31 23:59:59', 'Expired'), -- Thay 'Inactive' bằng 'Expired'
(6, 3, 'Admin', 3, '2024-05-05 11:00:00', '2024-12-31 23:59:59', 'Active'),
(7, 1, 'Read-Write', 1, '2024-06-15 09:00:00', '2024-12-31 23:59:59', 'Revoked'), -- Thay 'Suspended' bằng 'Revoked'
(8, 2, 'Admin', 3, '2024-07-01 16:00:00', '2024-12-31 23:59:59', 'Active'),
(9, 3, 'Read-Only', 2, '2024-08-20 17:00:00', '2024-12-31 23:59:59', 'Active'),
(10, 2, 'Read-Write', 1, '2024-09-10 12:00:00', '2024-12-31 23:59:59', 'Active');


SELECT * FROM User_Project_Access
WHERE access_level = 'Admin';
