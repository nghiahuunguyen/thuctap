CREATE TABLE tbl_providers (
    provider_id SERIAL PRIMARY KEY,
    provider_name VARCHAR(100) NOT NULL,
    contact_info VARCHAR(255),
    website VARCHAR(255),
    provider_type TEXT NOT NULL CHECK (provider_type IN ('Cloud', 'SaaS', 'Hardware', 'Software', 'Service')),
    account_manager_name VARCHAR(100),
    account_manager_email VARCHAR(100),
    contract_start_date DATE NOT NULL,
    contract_end_date DATE NOT NULL CHECK (contract_end_date > contract_start_date),
    payment_terms VARCHAR(50) NOT NULL,
    status TEXT DEFAULT 'Active' CHECK (status IN ('Active', 'Inactive', 'Suspended'))
);

CREATE TABLE tbl_projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL,
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE CHECK (end_date IS NULL OR end_date >= start_date),
    project_manager VARCHAR(100) NOT NULL,
    department VARCHAR(100) NOT NULL,
    priority TEXT DEFAULT 'Medium' CHECK (priority IN ('Low', 'Medium', 'High', 'Critical')),
    status TEXT DEFAULT 'Planning' CHECK (status IN ('Planning', 'In Progress', 'On Hold', 'Completed', 'Cancelled')),
    budget_allocated DECIMAL(15, 2) NOT NULL DEFAULT 0.00 CHECK (budget_allocated >= 0),
    client_name VARCHAR(100)
);

CREATE TABLE tbl_resources (
    resource_id SERIAL PRIMARY KEY,
    resource_name VARCHAR(100) NOT NULL,
    fk_provider_id INT NOT NULL REFERENCES tbl_providers(provider_id) ON DELETE RESTRICT,
    resource_type VARCHAR(50) NOT NULL,
    configuration TEXT,
    subscription_type TEXT NOT NULL CHECK (subscription_type IN ('Monthly', 'Yearly', 'One-time', 'Pay-as-you-go')),
    unit_price DECIMAL(10, 2) NOT NULL DEFAULT 0.00 CHECK (unit_price >= 0),
    recommended_capacity INT NOT NULL DEFAULT 1 CHECK (recommended_capacity > 0),
    efficiency_rating DECIMAL(3, 2) NOT NULL CHECK (efficiency_rating BETWEEN 0.00 AND 1.00)
);

CREATE TABLE tbl_costs (
    cost_id SERIAL PRIMARY KEY,
    fk_project_id INT NOT NULL REFERENCES tbl_projects(project_id) ON DELETE CASCADE,
    fk_resource_id INT NOT NULL REFERENCES tbl_resources(resource_id) ON DELETE RESTRICT,
    cost_amount DECIMAL(15, 2) NOT NULL CHECK (cost_amount > 0),
    cost_date DATE NOT NULL,
    cost_type TEXT NOT NULL CHECK (cost_type IN ('Operational', 'Subscription', 'Licensing', 'Infrastructure', 'Maintenance')),
    billing_cycle TEXT NOT NULL CHECK (billing_cycle IN ('Monthly', 'Quarterly', 'Annually')),
    payment_method TEXT NOT NULL CHECK (payment_method IN ('Credit Card', 'Bank Transfer', 'Invoice', 'Direct Debit')),
    invoice_number VARCHAR(50) UNIQUE,
    notes TEXT
);

CREATE TABLE tbl_cost_alerts (
    alert_id SERIAL PRIMARY KEY,
    fk_project_id INT REFERENCES tbl_projects(project_id) ON DELETE CASCADE,
    fk_resource_id INT REFERENCES tbl_resources(resource_id) ON DELETE CASCADE,
    alert_type TEXT NOT NULL CHECK (alert_type IN ('Budget Exceed', 'Unusual Spending', 'Subscription Expiry', 'Resource Underutilization')),
    threshold_amount DECIMAL(15, 2) CHECK (threshold_amount > 0),
    current_amount DECIMAL(15, 2) CHECK (current_amount >= 0),
    alert_date TIMESTAMP NOT NULL,
    status TEXT DEFAULT 'Active' CHECK (status IN ('Active', 'Resolved', 'Ignored')),
    notification_sent BOOLEAN DEFAULT FALSE
);

CREATE TABLE tbl_resource_utilization (
    utilization_id SERIAL PRIMARY KEY,
    fk_resource_id INT NOT NULL REFERENCES tbl_resources(resource_id) ON DELETE CASCADE,
    fk_project_id INT NOT NULL REFERENCES tbl_projects(project_id) ON DELETE CASCADE,
    record_date DATE NOT NULL,
    cpu_utilization DECIMAL(5, 2) NOT NULL CHECK (cpu_utilization BETWEEN 0 AND 100),
    memory_utilization DECIMAL(5, 2) NOT NULL CHECK (memory_utilization BETWEEN 0 AND 100),
    storage_utilization DECIMAL(5, 2) NOT NULL CHECK (storage_utilization BETWEEN 0 AND 100),
    network_traffic DECIMAL(15, 2) NOT NULL,
    active_users INT NOT NULL DEFAULT 0,
    performance_score DECIMAL(4, 2) NOT NULL CHECK (performance_score BETWEEN 0 AND 10)
);

CREATE INDEX idx_provider_type ON tbl_providers (provider_type, status);
CREATE INDEX idx_provider_name ON tbl_providers (provider_name);

CREATE INDEX idx_project_priority ON tbl_projects (priority, status);
CREATE INDEX idx_project_department ON tbl_projects (department);
CREATE INDEX idx_project_manager ON tbl_projects (project_manager);

CREATE INDEX idx_resource_provider ON tbl_resources (fk_provider_id);
CREATE INDEX idx_resource_type ON tbl_resources (resource_type);
CREATE INDEX idx_resource_subscription ON tbl_resources (subscription_type, unit_price);

CREATE INDEX idx_cost_project ON tbl_costs (fk_project_id);
CREATE INDEX idx_cost_resource ON tbl_costs (fk_resource_id);
CREATE INDEX idx_cost_date ON tbl_costs (cost_date);
CREATE INDEX idx_cost_type ON tbl_costs (cost_type);

CREATE INDEX idx_alert_project ON tbl_cost_alerts (fk_project_id);
CREATE INDEX idx_alert_resource ON tbl_cost_alerts (fk_resource_id);
CREATE INDEX idx_alert_type ON tbl_cost_alerts (alert_type, status);

CREATE INDEX idx_utilization_resource ON tbl_resource_utilization (fk_resource_id);
CREATE INDEX idx_utilization_project ON tbl_resource_utilization (fk_project_id);
CREATE INDEX idx_utilization_date ON tbl_resource_utilization (record_date);

INSERT INTO tbl_providers (provider_name, contact_info, website, provider_type, account_manager_name, account_manager_email, contract_start_date, contract_end_date, payment_terms, status)
VALUES 
('IBM Cloud', 'contact@ibm.com', 'https://www.ibm.com/cloud', 'Cloud', 'Alice Johnson', 'alice.johnson@ibm.com', '2024-01-01', '2025-01-01', 'Net 30', 'Active'),
('Oracle Cloud', 'support@oracle.com', 'https://cloud.oracle.com', 'Cloud', 'Bob Smith', 'bob.smith@oracle.com', '2024-02-01', '2025-02-01', 'Net 30', 'Active'),
('Salesforce', 'contact@salesforce.com', 'https://www.salesforce.com', 'SaaS', 'Charlie Davis', 'charlie.davis@salesforce.com', '2024-03-01', '2025-03-01', 'Net 60', 'Active'),
('Alibaba Cloud', 'support@alibaba.com', 'https://www.alibabacloud.com', 'Cloud', 'David Lee', 'david.lee@alibaba.com', '2024-04-01', '2025-04-01', 'Net 45', 'Active'),
('DigitalOcean', 'support@digitalocean.com', 'https://www.digitalocean.com', 'Cloud', 'Eve Thompson', 'eve.thompson@digitalocean.com', '2024-05-01', '2025-05-01', 'Net 30', 'Active');

INSERT INTO tbl_projects (project_name, description, start_date, end_date, project_manager, department, priority, status, budget_allocated, client_name)
VALUES 
('AI Development', 'Develop an AI model for automation', '2024-01-10', '2024-06-30', 'Sarah Connor', 'R&D', 'Critical', 'In Progress', 200000.00, 'Skynet Inc.'),
('Website Overhaul', 'Upgrade company website with modern technologies', '2024-02-01', '2024-05-31', 'Michael Scott', 'IT', 'High', 'Planning', 75000.00, 'Dunder Mifflin'),
('Cloud Migration', 'Move legacy systems to cloud infrastructure', '2024-01-15', '2024-03-31', 'Jim Halpert', 'IT', 'Medium', 'In Progress', 50000.00, 'Sabre Corp.'),
('Market Research', 'Conduct market research for new product lines', '2024-03-01', '2024-08-01', 'Pam Beesly', 'Marketing', 'Low', 'Planning', 30000.00, 'Paper Supply LLC'),
('Security Audit', 'Perform a cloud security audit for client systems', '2024-02-15', '2024-04-15', 'Dwight Schrute', 'Security', 'Critical', 'Planning', 90000.00, 'BeetFarm Tech.');

INSERT INTO tbl_resources (resource_name, fk_provider_id, resource_type, configuration, subscription_type, unit_price, recommended_capacity, efficiency_rating)
VALUES 
('IBM Watson AI', 1, 'AI', 'Watson Assistant, Standard Plan', 'Monthly', 300.00, 5, 0.90),
('Oracle DB Cloud', 2, 'Database', 'Oracle Autonomous Database', 'Yearly', 1200.00, 3, 0.85),
('Salesforce CRM', 3, 'CRM', 'Professional Edition', 'Monthly', 150.00, 10, 0.92),
('Alibaba ECS Instance', 4, 'Compute', '2 vCPU, 4GB RAM', 'Pay-as-you-go', 0.20, 1, 0.88),
('DigitalOcean Droplet', 5, 'Compute', '1 vCPU, 1GB RAM', 'Monthly', 5.00, 15, 0.87);

INSERT INTO tbl_costs (fk_project_id, fk_resource_id, cost_amount, cost_date, cost_type, billing_cycle, payment_method, invoice_number, notes)
VALUES 
(1, 1, 300.00, '2024-02-01', 'Operational', 'Monthly', 'Credit Card', 'INV001', 'Subscription for Watson AI'),
(2, 2, 1200.00, '2024-01-15', 'Subscription', 'Annually', 'Bank Transfer', 'INV002', 'Yearly Oracle DB Cloud subscription'),
(3, 3, 150.00, '2024-02-10', 'Licensing', 'Monthly', 'Credit Card', 'INV003', 'Salesforce CRM license'),
(4, 4, 120.00, '2024-02-20', 'Operational', 'Monthly', 'Direct Debit', 'INV004', 'Alibaba ECS instance usage'),
(5, 5, 5.00, '2024-02-25', 'Infrastructure', 'Monthly', 'Credit Card', 'INV005', 'DigitalOcean droplet usage');

INSERT INTO tbl_cost_alerts (fk_project_id, fk_resource_id, alert_type, threshold_amount, current_amount, alert_date, status, notification_sent)
VALUES 
(1, 1, 'Budget Exceed', 1000.00, 1300.00, '2024-02-10 10:00:00', 'Active', TRUE),
(2, 2, 'Unusual Spending', 900.00, 1200.00, '2024-01-20 14:00:00', 'Resolved', TRUE),
(3, 3, 'Resource Underutilization', 500.00, 150.00, '2024-02-15 16:30:00', 'Active', FALSE),
(4, 4, 'Subscription Expiry', NULL, NULL, '2024-03-01 09:15:00', 'Ignored', FALSE),
(5, 5, 'Budget Exceed', 50.00, 75.00, '2024-02-25 11:00:00', 'Resolved', TRUE);

INSERT INTO tbl_resource_utilization (fk_resource_id, fk_project_id, record_date, cpu_utilization, memory_utilization, storage_utilization, network_traffic, active_users, performance_score)
VALUES 
(1, 1, '2024-02-01', 70.5, 65.3, 90.0, 1000.75, 20, 9.00),
(2, 2, '2024-02-01', 50.0, 45.0, 60.0, 750.30, 8, 8.50),
(3, 3, '2024-02-01', 30.0, 25.0, 40.0, 500.10, 15, 8.20),
(4, 4, '2024-02-01', 20.0, 18.0, 30.0, 200.75, 5, 7.80),
(5, 5, '2024-02-01', 85.0, 80.0, 95.0, 1500.25, 12, 9.10);
