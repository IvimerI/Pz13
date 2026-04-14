/* =========================================================
   Практическая работа №13 и №15
   Тема: Управление активами компании
   СУБД: Microsoft SQL Server
   ========================================================= */

-- =========================================================
-- 1. Создание базы данных
-- =========================================================
IF DB_ID('AssetManagementDB') IS NULL
BEGIN
    CREATE DATABASE AssetManagementDB;
END;
GO

USE AssetManagementDB;
GO

-- =========================================================
-- 2. Создание схемы
-- =========================================================
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'asset_mgmt')
BEGIN
    EXEC('CREATE SCHEMA asset_mgmt');
END;
GO

-- =========================================================
-- 3. Создание ролей
-- =========================================================
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'asset_user_role')
    CREATE ROLE asset_user_role;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'asset_manager_role')
    CREATE ROLE asset_manager_role;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'asset_admin_role')
    CREATE ROLE asset_admin_role;
GO

-- =========================================================
-- 4. Удаление объектов при повторном запуске
-- =========================================================
IF OBJECT_ID('asset_mgmt.v_balance_report', 'V') IS NOT NULL DROP VIEW asset_mgmt.v_balance_report;
IF OBJECT_ID('asset_mgmt.v_asset_full_info', 'V') IS NOT NULL DROP VIEW asset_mgmt.v_asset_full_info;
GO

IF OBJECT_ID('asset_mgmt.inventory_results', 'U') IS NOT NULL DROP TABLE asset_mgmt.inventory_results;
IF OBJECT_ID('asset_mgmt.inventory_sessions', 'U') IS NOT NULL DROP TABLE asset_mgmt.inventory_sessions;
IF OBJECT_ID('asset_mgmt.asset_movements', 'U') IS NOT NULL DROP TABLE asset_mgmt.asset_movements;
IF OBJECT_ID('asset_mgmt.maintenance_events', 'U') IS NOT NULL DROP TABLE asset_mgmt.maintenance_events;
IF OBJECT_ID('asset_mgmt.maintenance_plans', 'U') IS NOT NULL DROP TABLE asset_mgmt.maintenance_plans;
IF OBJECT_ID('asset_mgmt.revaluation_history', 'U') IS NOT NULL DROP TABLE asset_mgmt.revaluation_history;
IF OBJECT_ID('asset_mgmt.depreciation_history', 'U') IS NOT NULL DROP TABLE asset_mgmt.depreciation_history;
IF OBJECT_ID('asset_mgmt.documents', 'U') IS NOT NULL DROP TABLE asset_mgmt.documents;
IF OBJECT_ID('asset_mgmt.assets', 'U') IS NOT NULL DROP TABLE asset_mgmt.assets;
IF OBJECT_ID('asset_mgmt.maintenance_types', 'U') IS NOT NULL DROP TABLE asset_mgmt.maintenance_types;
IF OBJECT_ID('asset_mgmt.document_types', 'U') IS NOT NULL DROP TABLE asset_mgmt.document_types;
IF OBJECT_ID('asset_mgmt.vendors', 'U') IS NOT NULL DROP TABLE asset_mgmt.vendors;
IF OBJECT_ID('asset_mgmt.locations', 'U') IS NOT NULL DROP TABLE asset_mgmt.locations;
IF OBJECT_ID('asset_mgmt.asset_statuses', 'U') IS NOT NULL DROP TABLE asset_mgmt.asset_statuses;
IF OBJECT_ID('asset_mgmt.asset_categories', 'U') IS NOT NULL DROP TABLE asset_mgmt.asset_categories;
IF OBJECT_ID('asset_mgmt.system_users', 'U') IS NOT NULL DROP TABLE asset_mgmt.system_users;
IF OBJECT_ID('asset_mgmt.employees', 'U') IS NOT NULL DROP TABLE asset_mgmt.employees;
IF OBJECT_ID('asset_mgmt.departments', 'U') IS NOT NULL DROP TABLE asset_mgmt.departments;
IF OBJECT_ID('asset_mgmt.role_permissions', 'U') IS NOT NULL DROP TABLE asset_mgmt.role_permissions;
IF OBJECT_ID('asset_mgmt.permissions', 'U') IS NOT NULL DROP TABLE asset_mgmt.permissions;
IF OBJECT_ID('asset_mgmt.app_roles', 'U') IS NOT NULL DROP TABLE asset_mgmt.app_roles;
GO

-- =========================================================
-- 5. Таблицы безопасности и пользователей
-- =========================================================
CREATE TABLE asset_mgmt.app_roles (
    role_code       VARCHAR(20) PRIMARY KEY,
    role_name       NVARCHAR(100) NOT NULL UNIQUE,
    description     NVARCHAR(MAX) NULL
);
GO

CREATE TABLE asset_mgmt.permissions (
    permission_code VARCHAR(20) PRIMARY KEY,
    permission_name VARCHAR(100) NOT NULL UNIQUE,
    description     NVARCHAR(MAX) NULL
);
GO

CREATE TABLE asset_mgmt.role_permissions (
    role_code       VARCHAR(20) NOT NULL,
    permission_code VARCHAR(20) NOT NULL,
    CONSTRAINT PK_role_permissions PRIMARY KEY (role_code, permission_code),
    CONSTRAINT FK_role_permissions_role
        FOREIGN KEY (role_code) REFERENCES asset_mgmt.app_roles(role_code) ON DELETE CASCADE,
    CONSTRAINT FK_role_permissions_permission
        FOREIGN KEY (permission_code) REFERENCES asset_mgmt.permissions(permission_code) ON DELETE CASCADE
);
GO

CREATE TABLE asset_mgmt.departments (
    department_code VARCHAR(20) PRIMARY KEY,
    department_name NVARCHAR(150) NOT NULL UNIQUE
);
GO

CREATE TABLE asset_mgmt.employees (
    employee_code   VARCHAR(20) PRIMARY KEY,
    full_name       NVARCHAR(200) NOT NULL,
    position_name   NVARCHAR(150) NOT NULL,
    department_code VARCHAR(20) NOT NULL,
    email           VARCHAR(150) NOT NULL UNIQUE,
    phone           VARCHAR(30) NULL,
    is_active       BIT NOT NULL DEFAULT 1,
    created_at      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_employees_departments
        FOREIGN KEY (department_code) REFERENCES asset_mgmt.departments(department_code)
);
GO

CREATE TABLE asset_mgmt.system_users (
    user_code       VARCHAR(20) PRIMARY KEY,
    employee_code   VARCHAR(20) NOT NULL UNIQUE,
    login_name      VARCHAR(100) NOT NULL UNIQUE,
    role_code       VARCHAR(20) NOT NULL,
    is_active       BIT NOT NULL DEFAULT 1,
    created_at      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_system_users_employees
        FOREIGN KEY (employee_code) REFERENCES asset_mgmt.employees(employee_code),
    CONSTRAINT FK_system_users_roles
        FOREIGN KEY (role_code) REFERENCES asset_mgmt.app_roles(role_code)
);
GO

-- =========================================================
-- 6. Справочники
-- =========================================================
CREATE TABLE asset_mgmt.asset_categories (
    category_code VARCHAR(20) PRIMARY KEY,
    category_name NVARCHAR(150) NOT NULL UNIQUE,
    description   NVARCHAR(MAX) NULL
);
GO

CREATE TABLE asset_mgmt.asset_statuses (
    status_code   VARCHAR(20) PRIMARY KEY,
    status_name   NVARCHAR(150) NOT NULL UNIQUE,
    description   NVARCHAR(MAX) NULL
);
GO

CREATE TABLE asset_mgmt.locations (
    location_code VARCHAR(20) PRIMARY KEY,
    location_name NVARCHAR(200) NOT NULL UNIQUE,
    city          NVARCHAR(100) NULL,
    location_type NVARCHAR(100) NOT NULL
);
GO

CREATE TABLE asset_mgmt.vendors (
    vendor_code   VARCHAR(20) PRIMARY KEY,
    vendor_name   NVARCHAR(200) NOT NULL UNIQUE,
    country       NVARCHAR(100) NULL,
    email         VARCHAR(150) NULL,
    phone         VARCHAR(30) NULL
);
GO

CREATE TABLE asset_mgmt.document_types (
    document_type_code VARCHAR(20) PRIMARY KEY,
    document_type_name NVARCHAR(150) NOT NULL UNIQUE
);
GO

CREATE TABLE asset_mgmt.maintenance_types (
    maintenance_type_code VARCHAR(20) PRIMARY KEY,
    maintenance_type_name NVARCHAR(150) NOT NULL UNIQUE,
    recommended_interval_days INT NOT NULL DEFAULT 0,
    CONSTRAINT CK_maintenance_types_days CHECK (recommended_interval_days >= 0)
);
GO

-- =========================================================
-- 7. Основные таблицы
-- =========================================================
CREATE TABLE asset_mgmt.assets (
    asset_code           VARCHAR(20) PRIMARY KEY,
    asset_name           NVARCHAR(200) NOT NULL,
    category_code        VARCHAR(20) NOT NULL,
    inventory_number     VARCHAR(50) NOT NULL UNIQUE,
    serial_number        VARCHAR(100) NOT NULL UNIQUE,
    barcode              VARCHAR(50) NULL UNIQUE,
    acquisition_date     DATE NOT NULL,
    initial_cost         DECIMAL(14,2) NOT NULL,
    current_value        DECIMAL(14,2) NOT NULL,
    useful_life_months   INT NOT NULL,
    status_code          VARCHAR(20) NOT NULL,
    location_code        VARCHAR(20) NOT NULL,
    responsible_code     VARCHAR(20) NOT NULL,
    vendor_code          VARCHAR(20) NULL,
    notes                NVARCHAR(MAX) NULL,
    image                VARBINARY(MAX) NOT NULL,
    created_at           DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT CK_assets_initial_cost CHECK (initial_cost >= 0),
    CONSTRAINT CK_assets_current_value CHECK (current_value >= 0),
    CONSTRAINT CK_assets_useful_life CHECK (useful_life_months > 0),
    CONSTRAINT FK_assets_category
        FOREIGN KEY (category_code) REFERENCES asset_mgmt.asset_categories(category_code),
    CONSTRAINT FK_assets_status
        FOREIGN KEY (status_code) REFERENCES asset_mgmt.asset_statuses(status_code),
    CONSTRAINT FK_assets_location
        FOREIGN KEY (location_code) REFERENCES asset_mgmt.locations(location_code),
    CONSTRAINT FK_assets_responsible
        FOREIGN KEY (responsible_code) REFERENCES asset_mgmt.employees(employee_code),
    CONSTRAINT FK_assets_vendor
        FOREIGN KEY (vendor_code) REFERENCES asset_mgmt.vendors(vendor_code)
);
GO

CREATE TABLE asset_mgmt.documents (
    document_code       VARCHAR(20) PRIMARY KEY,
    document_type_code  VARCHAR(20) NOT NULL,
    asset_code          VARCHAR(20) NOT NULL,
    document_number     VARCHAR(100) NOT NULL UNIQUE,
    title               NVARCHAR(250) NOT NULL,
    issue_date          DATE NOT NULL,
    expiration_date     DATE NULL,
    issuer_name         NVARCHAR(200) NULL,
    file_path           NVARCHAR(300) NULL,
    CONSTRAINT FK_documents_document_type
        FOREIGN KEY (document_type_code) REFERENCES asset_mgmt.document_types(document_type_code),
    CONSTRAINT FK_documents_asset
        FOREIGN KEY (asset_code) REFERENCES asset_mgmt.assets(asset_code) ON DELETE CASCADE
);
GO

CREATE TABLE asset_mgmt.depreciation_history (
    depreciation_code VARCHAR(20) PRIMARY KEY,
    asset_code        VARCHAR(20) NOT NULL,
    period_start      DATE NOT NULL,
    period_end        DATE NOT NULL,
    amount            DECIMAL(14,2) NOT NULL,
    method_name       NVARCHAR(100) NOT NULL,
    CONSTRAINT CK_depreciation_amount CHECK (amount >= 0),
    CONSTRAINT CK_depreciation_period CHECK (period_end >= period_start),
    CONSTRAINT FK_depreciation_asset
        FOREIGN KEY (asset_code) REFERENCES asset_mgmt.assets(asset_code) ON DELETE CASCADE
);
GO

CREATE TABLE asset_mgmt.revaluation_history (
    revaluation_code VARCHAR(20) PRIMARY KEY,
    asset_code       VARCHAR(20) NOT NULL,
    revaluation_date DATE NOT NULL,
    old_value        DECIMAL(14,2) NOT NULL,
    new_value        DECIMAL(14,2) NOT NULL,
    reason           NVARCHAR(MAX) NULL,
    CONSTRAINT CK_revaluation_old CHECK (old_value >= 0),
    CONSTRAINT CK_revaluation_new CHECK (new_value >= 0),
    CONSTRAINT FK_revaluation_asset
        FOREIGN KEY (asset_code) REFERENCES asset_mgmt.assets(asset_code) ON DELETE CASCADE
);
GO

CREATE TABLE asset_mgmt.maintenance_plans (
    plan_code               VARCHAR(20) PRIMARY KEY,
    asset_code              VARCHAR(20) NOT NULL,
    maintenance_type_code   VARCHAR(20) NOT NULL,
    start_date              DATE NOT NULL,
    next_due_date           DATE NOT NULL,
    assigned_employee_code  VARCHAR(20) NULL,
    is_active               BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_maintenance_plans_asset
        FOREIGN KEY (asset_code) REFERENCES asset_mgmt.assets(asset_code) ON DELETE CASCADE,
    CONSTRAINT FK_maintenance_plans_type
        FOREIGN KEY (maintenance_type_code) REFERENCES asset_mgmt.maintenance_types(maintenance_type_code),
    CONSTRAINT FK_maintenance_plans_employee
        FOREIGN KEY (assigned_employee_code) REFERENCES asset_mgmt.employees(employee_code)
);
GO

CREATE TABLE asset_mgmt.maintenance_events (
    event_code             VARCHAR(20) PRIMARY KEY,
    asset_code             VARCHAR(20) NOT NULL,
    maintenance_type_code  VARCHAR(20) NOT NULL,
    event_date             DATE NOT NULL,
    performed_by_code      VARCHAR(20) NULL,
    result_summary         NVARCHAR(MAX) NULL,
    cost_amount            DECIMAL(14,2) NOT NULL DEFAULT 0,
    CONSTRAINT CK_maintenance_events_cost CHECK (cost_amount >= 0),
    CONSTRAINT FK_maintenance_events_asset
        FOREIGN KEY (asset_code) REFERENCES asset_mgmt.assets(asset_code) ON DELETE CASCADE,
    CONSTRAINT FK_maintenance_events_type
        FOREIGN KEY (maintenance_type_code) REFERENCES asset_mgmt.maintenance_types(maintenance_type_code),
    CONSTRAINT FK_maintenance_events_employee
        FOREIGN KEY (performed_by_code) REFERENCES asset_mgmt.employees(employee_code)
);
GO

CREATE TABLE asset_mgmt.inventory_sessions (
    session_code       VARCHAR(20) PRIMARY KEY,
    session_name       NVARCHAR(250) NOT NULL,
    location_code      VARCHAR(20) NOT NULL,
    start_date         DATE NOT NULL,
    end_date           DATE NULL,
    lead_employee_code VARCHAR(20) NULL,
    session_status     NVARCHAR(50) NOT NULL,
    CONSTRAINT CK_inventory_sessions_dates CHECK (end_date IS NULL OR end_date >= start_date),
    CONSTRAINT FK_inventory_sessions_location
        FOREIGN KEY (location_code) REFERENCES asset_mgmt.locations(location_code),
    CONSTRAINT FK_inventory_sessions_employee
        FOREIGN KEY (lead_employee_code) REFERENCES asset_mgmt.employees(employee_code)
);
GO

CREATE TABLE asset_mgmt.inventory_results (
    result_code           VARCHAR(20) PRIMARY KEY,
    session_code          VARCHAR(20) NOT NULL,
    asset_code            VARCHAR(20) NOT NULL,
    actual_location_code  VARCHAR(20) NULL,
    condition_note        NVARCHAR(100) NOT NULL,
    comment_text          NVARCHAR(MAX) NULL,
    CONSTRAINT UQ_inventory_results UNIQUE (session_code, asset_code),
    CONSTRAINT FK_inventory_results_session
        FOREIGN KEY (session_code) REFERENCES asset_mgmt.inventory_sessions(session_code) ON DELETE CASCADE,
    CONSTRAINT FK_inventory_results_asset
        FOREIGN KEY (asset_code) REFERENCES asset_mgmt.assets(asset_code) ON DELETE CASCADE,
    CONSTRAINT FK_inventory_results_location
        FOREIGN KEY (actual_location_code) REFERENCES asset_mgmt.locations(location_code)
);
GO

CREATE TABLE asset_mgmt.asset_movements (
    movement_code       VARCHAR(20) PRIMARY KEY,
    asset_code          VARCHAR(20) NOT NULL,
    from_location_code  VARCHAR(20) NOT NULL,
    to_location_code    VARCHAR(20) NOT NULL,
    movement_date       DATE NOT NULL,
    moved_by_code       VARCHAR(20) NULL,
    accepted_by_code    VARCHAR(20) NULL,
    document_code       VARCHAR(20) NULL,
    basis               NVARCHAR(MAX) NULL,
    CONSTRAINT CK_asset_movements_diff CHECK (from_location_code <> to_location_code),
    CONSTRAINT FK_asset_movements_asset
        FOREIGN KEY (asset_code) REFERENCES asset_mgmt.assets(asset_code) ON DELETE CASCADE,
    CONSTRAINT FK_asset_movements_from_location
        FOREIGN KEY (from_location_code) REFERENCES asset_mgmt.locations(location_code),
    CONSTRAINT FK_asset_movements_to_location
        FOREIGN KEY (to_location_code) REFERENCES asset_mgmt.locations(location_code),
    CONSTRAINT FK_asset_movements_moved_by
        FOREIGN KEY (moved_by_code) REFERENCES asset_mgmt.employees(employee_code),
    CONSTRAINT FK_asset_movements_accepted_by
        FOREIGN KEY (accepted_by_code) REFERENCES asset_mgmt.employees(employee_code),
    CONSTRAINT FK_asset_movements_document
        FOREIGN KEY (document_code) REFERENCES asset_mgmt.documents(document_code)
);
GO

-- =========================================================
-- 8. Индексы
-- =========================================================
CREATE INDEX IX_assets_category        ON asset_mgmt.assets(category_code);
CREATE INDEX IX_assets_status          ON asset_mgmt.assets(status_code);
CREATE INDEX IX_assets_location        ON asset_mgmt.assets(location_code);
CREATE INDEX IX_assets_responsible     ON asset_mgmt.assets(responsible_code);
CREATE INDEX IX_documents_asset        ON asset_mgmt.documents(asset_code);
CREATE INDEX IX_depreciation_asset     ON asset_mgmt.depreciation_history(asset_code);
CREATE INDEX IX_revaluation_asset      ON asset_mgmt.revaluation_history(asset_code);
CREATE INDEX IX_maint_plan_asset       ON asset_mgmt.maintenance_plans(asset_code);
CREATE INDEX IX_maint_event_asset      ON asset_mgmt.maintenance_events(asset_code);
CREATE INDEX IX_inventory_result_asset ON asset_mgmt.inventory_results(asset_code);
CREATE INDEX IX_movement_asset         ON asset_mgmt.asset_movements(asset_code);
GO

-- =========================================================
-- 9. Наполнение справочников
-- =========================================================
INSERT INTO asset_mgmt.app_roles (role_code, role_name, description) VALUES
('ADMIN',   N'Администратор', N'Полный доступ к данным и настройкам'),
('MANAGER', N'Менеджер',      N'Управление активами, документами, ТО и перемещениями'),
('USER',    N'Пользователь',  N'Просмотр доступных данных и отчетов');
GO

INSERT INTO asset_mgmt.permissions (permission_code, permission_name, description) VALUES
('PERM001', 'asset.read',         N'Просмотр активов'),
('PERM002', 'asset.create',       N'Создание активов'),
('PERM003', 'asset.update',       N'Редактирование активов'),
('PERM004', 'asset.delete',       N'Удаление активов'),
('PERM005', 'location.read',      N'Просмотр мест расположения'),
('PERM006', 'employee.read',      N'Просмотр сотрудников'),
('PERM007', 'document.read',      N'Просмотр документов'),
('PERM008', 'document.manage',    N'Управление документами'),
('PERM009', 'movement.read',      N'Просмотр перемещений'),
('PERM010', 'movement.manage',    N'Управление перемещениями'),
('PERM011', 'maintenance.read',   N'Просмотр ТО'),
('PERM012', 'maintenance.manage', N'Управление ТО'),
('PERM013', 'inventory.read',     N'Просмотр инвентаризации'),
('PERM014', 'inventory.manage',   N'Проведение инвентаризации'),
('PERM015', 'report.read',        N'Просмотр отчетности'),
('PERM016', 'user.manage',        N'Управление пользователями'),
('PERM017', 'role.manage',        N'Управление ролями'),
('PERM018', 'depreciation.read',  N'Просмотр амортизации'),
('PERM019', 'depreciation.manage',N'Управление амортизацией'),
('PERM020', 'revaluation.manage', N'Управление переоценкой');
GO

INSERT INTO asset_mgmt.role_permissions (role_code, permission_code)
SELECT 'ADMIN', permission_code FROM asset_mgmt.permissions;
GO

INSERT INTO asset_mgmt.role_permissions (role_code, permission_code) VALUES
('MANAGER','PERM001'),
('MANAGER','PERM002'),
('MANAGER','PERM003'),
('MANAGER','PERM005'),
('MANAGER','PERM006'),
('MANAGER','PERM007'),
('MANAGER','PERM008'),
('MANAGER','PERM009'),
('MANAGER','PERM010'),
('MANAGER','PERM011'),
('MANAGER','PERM012'),
('MANAGER','PERM013'),
('MANAGER','PERM014'),
('MANAGER','PERM015'),
('MANAGER','PERM018'),
('MANAGER','PERM019'),
('MANAGER','PERM020'),
('USER','PERM001'),
('USER','PERM005'),
('USER','PERM006'),
('USER','PERM007'),
('USER','PERM009'),
('USER','PERM011'),
('USER','PERM013'),
('USER','PERM015'),
('USER','PERM018');
GO

INSERT INTO asset_mgmt.departments (department_code, department_name) VALUES
('DEP001', N'Администрация'),
('DEP002', N'Бухгалтерия'),
('DEP003', N'Отдел закупок'),
('DEP004', N'IT-отдел'),
('DEP005', N'Отдел кадров'),
('DEP006', N'Склад'),
('DEP007', N'Производственный цех №1'),
('DEP008', N'Производственный цех №2'),
('DEP009', N'Лаборатория контроля качества'),
('DEP010', N'Отдел продаж'),
('DEP011', N'Маркетинг'),
('DEP012', N'Юридический отдел'),
('DEP013', N'Служба безопасности'),
('DEP014', N'Логистика'),
('DEP015', N'Сервисная служба'),
('DEP016', N'Отдел эксплуатации'),
('DEP017', N'Филиал Санкт-Петербург'),
('DEP018', N'Филиал Казань'),
('DEP019', N'Филиал Екатеринбург'),
('DEP020', N'Архив');
GO

INSERT INTO asset_mgmt.employees (employee_code, full_name, position_name, department_code, email, phone) VALUES
('EMP001', N'Иванов Иван Иванович', N'Главный бухгалтер',        'DEP002', 'user01@company.local', '+7-900-101-11'),
('EMP002', N'Петров Петр Петрович', N'Системный администратор',  'DEP004', 'user02@company.local', '+7-900-102-12'),
('EMP003', N'Сидоров Алексей Олегович', N'Инженер по эксплуатации','DEP016', 'user03@company.local', '+7-900-103-13'),
('EMP004', N'Смирнова Анна Викторовна', N'Специалист по закупкам', 'DEP003', 'user04@company.local', '+7-900-104-14'),
('EMP005', N'Кузнецова Мария Сергеевна', N'HR-менеджер',          'DEP005', 'user05@company.local', '+7-900-105-15'),
('EMP006', N'Орлов Николай Дмитриевич', N'Кладовщик',            'DEP006', 'user06@company.local', '+7-900-106-16'),
('EMP007', N'Васильев Артем Юрьевич', N'Начальник цеха',          'DEP007', 'user07@company.local', '+7-900-107-17'),
('EMP008', N'Федорова Ольга Андреевна', N'Инженер-лаборант',      'DEP009', 'user08@company.local', '+7-900-108-18'),
('EMP009', N'Павлов Сергей Николаевич', N'Менеджер по продажам',  'DEP010', 'user09@company.local', '+7-900-109-19'),
('EMP010', N'Соколова Ирина Павловна', N'Маркетолог',            'DEP011', 'user10@company.local', '+7-900-110-20'),
('EMP011', N'Зайцева Елена Игоревна', N'Юрисконсульт',           'DEP012', 'user11@company.local', '+7-900-111-21'),
('EMP012', N'Михайлов Денис Андреевич', N'Специалист по безопасности', 'DEP013', 'user12@company.local', '+7-900-112-22'),
('EMP013', N'Тарасов Роман Викторович', N'Логист',               'DEP014', 'user13@company.local', '+7-900-113-23'),
('EMP014', N'Николаева Юлия Олеговна', N'Сервисный инженер',      'DEP015', 'user14@company.local', '+7-900-114-24'),
('EMP015', N'Алексеев Дмитрий Сергеевич', N'Администратор офиса', 'DEP001', 'user15@company.local', '+7-900-115-25'),
('EMP016', N'Попова Наталья Владимировна', N'Руководитель филиала','DEP017', 'user16@company.local', '+7-900-116-26'),
('EMP017', N'Громов Андрей Ильич', N'Техник',                    'DEP018', 'user17@company.local', '+7-900-117-27'),
('EMP018', N'Белова Татьяна Николаевна', N'Экономист',           'DEP002', 'user18@company.local', '+7-900-118-28'),
('EMP019', N'Комаров Олег Павлович', N'Аналитик',                'DEP004', 'user19@company.local', '+7-900-119-29'),
('EMP020', N'Тихонова Дарья Алексеевна', N'Специалист по лицензированию','DEP004', 'user20@company.local', '+7-900-120-30'),
('EMP021', N'Баранов Кирилл Игоревич', N'Инженер сети',          'DEP004', 'user21@company.local', '+7-900-121-31'),
('EMP022', N'Семенова Алина Романовна', N'Бухгалтер',            'DEP002', 'user22@company.local', '+7-900-122-32'),
('EMP023', N'Лебедев Михаил Евгеньевич', N'Инженер ТО',          'DEP015', 'user23@company.local', '+7-900-123-33'),
('EMP024', N'Крылова Екатерина Вадимовна', N'Закупщик',          'DEP003', 'user24@company.local', '+7-900-124-34'),
('EMP025', N'Виноградов Илья Олегович', N'Складской оператор',   'DEP006', 'user25@company.local', '+7-900-125-35'),
('EMP026', N'Романова Светлана Ильинична', N'Менеджер активов',  'DEP001', 'user26@company.local', '+7-900-126-36'),
('EMP027', N'Киселев Арсений Петрович', N'Мастер участка',       'DEP008', 'user27@company.local', '+7-900-127-37'),
('EMP028', N'Егорова Полина Сергеевна', N'Лаборант',             'DEP009', 'user28@company.local', '+7-900-128-38'),
('EMP029', N'Морозова Виктория Андреевна', N'Специалист офиса',  'DEP001', 'user29@company.local', '+7-900-129-39'),
('EMP030', N'Чернов Владислав Денисович', N'Специалист склада',  'DEP006', 'user30@company.local', '+7-900-130-40');
GO

INSERT INTO asset_mgmt.system_users (user_code, employee_code, login_name, role_code, is_active) VALUES
('USR001', 'EMP001', 'login01', 'ADMIN',   1),
('USR002', 'EMP002', 'login02', 'ADMIN',   1),
('USR003', 'EMP003', 'login03', 'MANAGER', 1),
('USR004', 'EMP004', 'login04', 'MANAGER', 1),
('USR005', 'EMP005', 'login05', 'MANAGER', 1),
('USR006', 'EMP006', 'login06', 'MANAGER', 1),
('USR007', 'EMP007', 'login07', 'MANAGER', 1),
('USR008', 'EMP008', 'login08', 'MANAGER', 1),
('USR009', 'EMP009', 'login09', 'USER',    1),
('USR010', 'EMP010', 'login10', 'USER',    1),
('USR011', 'EMP011', 'login11', 'USER',    1),
('USR012', 'EMP012', 'login12', 'USER',    1),
('USR013', 'EMP013', 'login13', 'USER',    1),
('USR014', 'EMP014', 'login14', 'USER',    1),
('USR015', 'EMP015', 'login15', 'USER',    1),
('USR016', 'EMP016', 'login16', 'USER',    1),
('USR017', 'EMP017', 'login17', 'USER',    1),
('USR018', 'EMP018', 'login18', 'USER',    1),
('USR019', 'EMP019', 'login19', 'USER',    1),
('USR020', 'EMP020', 'login20', 'USER',    1);
GO

INSERT INTO asset_mgmt.asset_categories (category_code, category_name, description) VALUES
('CAT001', N'Основные средства', N'Материальные активы длительного использования'),
('CAT002', N'Нематериальные активы', N'ПО, лицензии, патенты'),
('CAT003', N'МПЗ', N'Материально-производственные запасы'),
('CAT004', N'Компьютерная техника', N'ПК, ноутбуки, моноблоки'),
('CAT005', N'Серверное оборудование', N'Серверы и СХД'),
('CAT006', N'Сетевое оборудование', N'Маршрутизаторы, коммутаторы'),
('CAT007', N'Офисная мебель', N'Столы, шкафы, кресла'),
('CAT008', N'Периферийные устройства', N'Принтеры, сканеры, МФУ'),
('CAT009', N'Производственное оборудование', N'Станки и линии'),
('CAT010', N'Складская техника', N'Погрузчики, штабелеры'),
('CAT011', N'Измерительные приборы', N'Осциллографы, мультиметры'),
('CAT012', N'Транспортные средства', N'Автомобили и электрокары'),
('CAT013', N'Климатическое оборудование', N'Кондиционеры, тепловые завесы'),
('CAT014', N'Системы безопасности', N'Камеры, СКУД, сигнализация'),
('CAT015', N'Программное обеспечение', N'ОС и прикладное ПО'),
('CAT016', N'Лицензии и подписки', N'SaaS и корпоративные лицензии'),
('CAT017', N'Инструменты и оснастка', N'Ручной и электроинструмент'),
('CAT018', N'Торговое оборудование', N'POS, кассы, витрины'),
('CAT019', N'Лабораторное оборудование', N'Анализаторы, микроскопы'),
('CAT020', N'Прочие активы', N'Прочие материальные и нематериальные активы');
GO

INSERT INTO asset_mgmt.asset_statuses (status_code, status_name, description) VALUES
('ST001', N'В эксплуатации', N'Актив используется по назначению'),
('ST002', N'На складе', N'Актив находится на складе'),
('ST003', N'На обслуживании', N'Проводится ТО'),
('ST004', N'В ремонте', N'Актив передан в ремонт'),
('ST005', N'Забронирован', N'Зарезервирован'),
('ST006', N'На инвентаризации', N'Проверяется в рамках инвентаризации'),
('ST007', N'Списан', N'Выведен из эксплуатации'),
('ST008', N'Утилизирован', N'Уничтожен'),
('ST009', N'Продан', N'Реализован'),
('ST010', N'Передан в аренду', N'Временно передан'),
('ST011', N'Возвращен из аренды', N'Вернулся на предприятие'),
('ST012', N'Требует диагностики', N'Нужно установить причину неисправности'),
('ST013', N'Ожидает поставки', N'Заказан и ожидается'),
('ST014', N'Ожидает ввода в эксплуатацию', N'Получен, но не запущен'),
('ST015', N'На переоценке', N'Проводится переоценка'),
('ST016', N'На консервации', N'Временно не используется'),
('ST017', N'Потерян', N'Местонахождение неизвестно'),
('ST018', N'Поврежден', N'Есть физические повреждения'),
('ST019', N'Внутреннее перемещение', N'В процессе перемещения'),
('ST020', N'Гарантийный случай', N'На гарантийном обслуживании');
GO

INSERT INTO asset_mgmt.locations (location_code, location_name, city, location_type) VALUES
('LOC001', N'Главный офис, 1 этаж', N'Москва', N'Офис'),
('LOC002', N'Главный офис, 2 этаж', N'Москва', N'Офис'),
('LOC003', N'Главный офис, серверная', N'Москва', N'Серверная'),
('LOC004', N'Главный офис, архив', N'Москва', N'Архив'),
('LOC005', N'Склад А, зона приемки', N'Москва', N'Склад'),
('LOC006', N'Склад А, стеллаж B-12', N'Москва', N'Склад'),
('LOC007', N'Склад B, зона хранения', N'Подольск', N'Склад'),
('LOC008', N'Производственный цех №1, линия 1', N'Тула', N'Цех'),
('LOC009', N'Производственный цех №1, линия 2', N'Тула', N'Цех'),
('LOC010', N'Производственный цех №2, участок сборки', N'Тула', N'Цех'),
('LOC011', N'Лаборатория, комната измерений', N'Тула', N'Лаборатория'),
('LOC012', N'Филиал СПб, офис 301', N'Санкт-Петербург', N'Офис'),
('LOC013', N'Филиал СПб, склад', N'Санкт-Петербург', N'Склад'),
('LOC014', N'Филиал Казань, офис 210', N'Казань', N'Офис'),
('LOC015', N'Филиал Казань, склад', N'Казань', N'Склад'),
('LOC016', N'Филиал Екатеринбург, офис 105', N'Екатеринбург', N'Офис'),
('LOC017', N'Филиал Екатеринбург, склад', N'Екатеринбург', N'Склад'),
('LOC018', N'Логистический терминал 2', N'Домодедово', N'Логистический центр'),
('LOC019', N'Сервисный центр, ремонтная зона', N'Москва', N'Сервис'),
('LOC020', N'Облачная площадка / лицензии', N'Онлайн', N'Виртуальная площадка');
GO

INSERT INTO asset_mgmt.vendors (vendor_code, vendor_name, country, email, phone) VALUES
('VEN001', N'ООО Технопоставка', N'Россия', 'equipment@tehnopostavka.ru', '+7-495-100-10-01'),
('VEN002', N'АО ИнфоСистемы', N'Россия', 'sales@infosystems.ru', '+7-495-100-10-02'),
('VEN003', N'SoftLine Enterprise', N'Россия', 'b2b@softline.example', '+7-495-100-10-03'),
('VEN004', N'Northwind Hardware', N'Казахстан', 'sales@northwind.example', '+7-727-100-10-04'),
('VEN005', N'ООО СкладСервис', N'Россия', 'order@skladservice.ru', '+7-495-100-10-05'),
('VEN006', N'Industrial Machines GmbH', N'Германия', 'kontakt@indmachines.example', '+49-30-100-10-06'),
('VEN007', N'Printer Solutions', N'Россия', 'office@printersolutions.ru', '+7-812-100-10-07'),
('VEN008', N'SecureVision', N'Россия', 'hello@securevision.ru', '+7-495-100-10-08'),
('VEN009', N'Cloud Contracts LLC', N'США', 'contracts@cloudcontracts.example', '+1-555-100-10-09'),
('VEN010', N'ООО Комфорт Мебель', N'Россия', 'corp@comfortmebel.ru', '+7-495-100-10-10'),
('VEN011', N'АО ЭнергоКлимат', N'Россия', 'sales@energoclimat.ru', '+7-495-100-10-11'),
('VEN012', N'Lab Instruments s.r.o.', N'Чехия', 'lab@instruments.example', '+420-2-100-10-12'),
('VEN013', N'AutoFleet', N'Россия', 'fleet@autofleet.ru', '+7-495-100-10-13'),
('VEN014', N'Лицензии Онлайн', N'Россия', 'license@liconline.ru', '+7-495-100-10-14'),
('VEN015', N'ООО Контроль-Качества', N'Россия', 'service@kk.ru', '+7-495-100-10-15'),
('VEN016', N'Datacenter Partners', N'Россия', 'dc@datacenter.example', '+7-495-100-10-16'),
('VEN017', N'ООО Инвентарь Плюс', N'Россия', 'sale@inventplus.ru', '+7-495-100-10-17'),
('VEN018', N'Retail Tech', N'Россия', 'retail@retailtech.ru', '+7-495-100-10-18'),
('VEN019', N'Factory Tooling', N'Китай', 'support@factorytooling.example', '+86-21-100-10-19'),
('VEN020', N'Enterprise Renewals', N'Россия', 'renewals@erenew.ru', '+7-495-100-10-20');
GO

INSERT INTO asset_mgmt.document_types (document_type_code, document_type_name) VALUES
('DT001', N'Акт приема-передачи'),
('DT002', N'Счет-фактура'),
('DT003', N'Товарная накладная'),
('DT004', N'Гарантийный талон'),
('DT005', N'Договор поставки'),
('DT006', N'Договор аренды'),
('DT007', N'Лицензионное соглашение'),
('DT008', N'Акт ввода в эксплуатацию'),
('DT009', N'Акт списания'),
('DT010', N'Инвентаризационная ведомость'),
('DT011', N'Заказ-наряд на ремонт'),
('DT012', N'Паспорт оборудования'),
('DT013', N'Сертификат соответствия'),
('DT014', N'Страховой полис'),
('DT015', N'Протокол поверки'),
('DT016', N'Акт переоценки'),
('DT017', N'Служебная записка'),
('DT018', N'Техническое задание'),
('DT019', N'Спецификация'),
('DT020', N'Отчет по амортизации');
GO

INSERT INTO asset_mgmt.maintenance_types (maintenance_type_code, maintenance_type_name, recommended_interval_days) VALUES
('MT001', N'Плановый осмотр', 90),
('MT002', N'Ежеквартальное ТО', 90),
('MT003', N'Полугодовое ТО', 180),
('MT004', N'Годовое ТО', 365),
('MT005', N'Замена расходных материалов', 60),
('MT006', N'Калибровка', 180),
('MT007', N'Поверка', 365),
('MT008', N'Диагностика', 30),
('MT009', N'Чистка и профилактика', 120),
('MT010', N'Обновление прошивки', 120),
('MT011', N'Обновление ПО', 30),
('MT012', N'Проверка лицензии', 365),
('MT013', N'Проверка аккумулятора', 180),
('MT014', N'Тестирование производительности', 90),
('MT015', N'Проверка безопасности', 180),
('MT016', N'Ремонт по заявке', 0),
('MT017', N'Гарантийное обслуживание', 0),
('MT018', N'Проверка маркировки', 365),
('MT019', N'Контроль срока службы', 365),
('MT020', N'Резервное копирование конфигурации', 30);
GO

-- =========================================================
-- 10. Генерация тестовых данных
-- =========================================================
DECLARE @i INT = 1;

WHILE @i <= 120
BEGIN
    DECLARE @asset_code       VARCHAR(20) = 'AST' + RIGHT('0000' + CAST(@i AS VARCHAR(10)), 4);
    DECLARE @category_num     INT = ((@i - 1) % 20) + 1;
    DECLARE @status_num       INT = ((@i - 1) % 20) + 1;
    DECLARE @location_num     INT = ((@i - 1) % 20) + 1;
    DECLARE @vendor_num       INT = ((@i - 1) % 20) + 1;
    DECLARE @employee_num     INT = ((@i - 1) % 30) + 1;

    DECLARE @category_code    VARCHAR(20) = 'CAT' + RIGHT('000' + CAST(@category_num AS VARCHAR(10)), 3);
    DECLARE @status_code      VARCHAR(20) = 'ST'  + RIGHT('000' + CAST(@status_num AS VARCHAR(10)), 3);
    DECLARE @location_code    VARCHAR(20) = 'LOC' + RIGHT('000' + CAST(@location_num AS VARCHAR(10)), 3);
    DECLARE @vendor_code      VARCHAR(20) = 'VEN' + RIGHT('000' + CAST(@vendor_num AS VARCHAR(10)), 3);
    DECLARE @responsible_code VARCHAR(20) = 'EMP' + RIGHT('000' + CAST(@employee_num AS VARCHAR(10)), 3);

    DECLARE @asset_name NVARCHAR(200) =
        CASE @category_num
            WHEN 1  THEN N'Сейф офисный'
            WHEN 2  THEN N'Корпоративная база знаний'
            WHEN 3  THEN N'Комплект расходных материалов'
            WHEN 4  THEN N'Ноутбук Lenovo ThinkPad'
            WHEN 5  THEN N'Сервер Dell PowerEdge'
            WHEN 6  THEN N'Маршрутизатор Mikrotik'
            WHEN 7  THEN N'Офисный стол'
            WHEN 8  THEN N'МФУ Kyocera'
            WHEN 9  THEN N'Производственный станок'
            WHEN 10 THEN N'Погрузчик электрический'
            WHEN 11 THEN N'Осциллограф цифровой'
            WHEN 12 THEN N'Служебный автомобиль'
            WHEN 13 THEN N'Кондиционер Daikin'
            WHEN 14 THEN N'IP-камера Hikvision'
            WHEN 15 THEN N'Microsoft Windows 11 Pro'
            WHEN 16 THEN N'Подписка Adobe Creative Cloud'
            WHEN 17 THEN N'Шуруповерт Makita'
            WHEN 18 THEN N'POS-терминал'
            WHEN 19 THEN N'Микроскоп лабораторный'
            ELSE N'Планшет для инвентаризации'
        END;

    DECLARE @acquisition_date DATE = DATEADD(DAY, -(@i * 17), CAST(GETDATE() AS DATE));
    DECLARE @initial_cost DECIMAL(14,2) = CAST(10000 + (@i * 2750) AS DECIMAL(14,2));
    DECLARE @current_value DECIMAL(14,2) = CAST((10000 + (@i * 2750)) * 0.62 AS DECIMAL(14,2));
    DECLARE @useful_life INT =
        CASE WHEN @category_num IN (2,15,16) THEN 36
             WHEN @category_num IN (9,12) THEN 84
             ELSE 60
        END;

    INSERT INTO asset_mgmt.assets
    (
        asset_code, asset_name, category_code, inventory_number, serial_number, barcode,
        acquisition_date, initial_cost, current_value, useful_life_months,
        status_code, location_code, responsible_code, vendor_code, notes, image
    )
    VALUES
    (
        @asset_code,
        @asset_name + N' #' + CAST(@i AS NVARCHAR(10)),
        @category_code,
        'INV-2026-' + RIGHT('0000' + CAST(@i AS VARCHAR(10)), 4),
        'SN-' + RIGHT('000000' + CAST(@i AS VARCHAR(10)), 6),
        'BC' + RIGHT('000000000000' + CAST(100000000000 + @i AS VARCHAR(20)), 12),
        @acquisition_date,
        @initial_cost,
        @current_value,
        @useful_life,
        @status_code,
        @location_code,
        @responsible_code,
        @vendor_code,
        N'Тестовая запись для проверки работоспособности системы.',
        CONVERT(VARBINARY(MAX), CONCAT('ASSET_IMAGE_', RIGHT('0000' + CAST(@i AS VARCHAR(10)), 4), '_', @category_code, '_', REPLACE(CONVERT(VARCHAR(10), @acquisition_date, 120), '-', '')))
    );

    SET @i += 1;
END;
GO

-- =========================================================
-- 11. Документы (120 записей)
-- =========================================================
DECLARE @d INT = 1;

WHILE @d <= 120
BEGIN
    DECLARE @doc_code      VARCHAR(20) = 'DOC' + RIGHT('0000' + CAST(@d AS VARCHAR(10)), 4);
    DECLARE @doc_type_num  INT = ((@d - 1) % 20) + 1;
    DECLARE @asset_num     INT = @d;
    DECLARE @doc_type_code VARCHAR(20) = 'DT' + RIGHT('000' + CAST(@doc_type_num AS VARCHAR(10)), 3);
    DECLARE @asset_code2   VARCHAR(20) = 'AST' + RIGHT('0000' + CAST(@asset_num AS VARCHAR(10)), 4);

    INSERT INTO asset_mgmt.documents
    (
        document_code, document_type_code, asset_code, document_number,
        title, issue_date, expiration_date, issuer_name, file_path
    )
    VALUES
    (
        @doc_code,
        @doc_type_code,
        @asset_code2,
        'DOC-2026-' + RIGHT('00000' + CAST(@d AS VARCHAR(10)), 5),
        N'Документ по активу ' + @asset_code2,
        DATEADD(DAY, -(@d * 3), CAST(GETDATE() AS DATE)),
        CASE WHEN @doc_type_num IN (4,6,7,14) THEN DATEADD(YEAR, 1, CAST(GETDATE() AS DATE)) ELSE NULL END,
        N'Внутренняя комиссия',
        N'/docs/' + CAST(YEAR(GETDATE()) AS NVARCHAR(4)) + N'/DOC-' + RIGHT('00000' + CAST(@d AS VARCHAR(10)), 5) + N'.pdf'
    );

    SET @d += 1;
END;
GO

-- =========================================================
-- 12. Амортизация (120 записей)
-- =========================================================
DECLARE @dp INT = 1;

WHILE @dp <= 120
BEGIN
    DECLARE @asset_code3 VARCHAR(20) = 'AST' + RIGHT('0000' + CAST(@dp AS VARCHAR(10)), 4);

    INSERT INTO asset_mgmt.depreciation_history
    (
        depreciation_code, asset_code, period_start, period_end, amount, method_name
    )
    SELECT
        'DP' + RIGHT('0000' + CAST(@dp AS VARCHAR(10)), 4),
        @asset_code3,
        DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1),
        DATEFROMPARTS(YEAR(GETDATE()) - 1, 12, 31),
        CAST(a.initial_cost * 0.12 AS DECIMAL(14,2)),
        N'Линейный метод'
    FROM asset_mgmt.assets a
    WHERE a.asset_code = @asset_code3;

    SET @dp += 1;
END;
GO

-- =========================================================
-- 13. Переоценка (30 записей)
-- =========================================================
DECLARE @rv INT = 1;

WHILE @rv <= 30
BEGIN
    DECLARE @asset_code4 VARCHAR(20) = 'AST' + RIGHT('0000' + CAST(@rv AS VARCHAR(10)), 4);

    INSERT INTO asset_mgmt.revaluation_history
    (
        revaluation_code, asset_code, revaluation_date, old_value, new_value, reason
    )
    SELECT
        'RV' + RIGHT('0000' + CAST(@rv AS VARCHAR(10)), 4),
        @asset_code4,
        DATEADD(DAY, -@rv, CAST(GETDATE() AS DATE)),
        a.current_value,
        CAST(a.current_value * 1.05 AS DECIMAL(14,2)),
        N'Плановая переоценка актива'
    FROM asset_mgmt.assets a
    WHERE a.asset_code = @asset_code4;

    SET @rv += 1;
END;
GO

-- =========================================================
-- 14. Планы ТО (40 записей)
-- =========================================================
DECLARE @mp INT = 1;

WHILE @mp <= 40
BEGIN
    INSERT INTO asset_mgmt.maintenance_plans
    (
        plan_code, asset_code, maintenance_type_code, start_date, next_due_date,
        assigned_employee_code, is_active
    )
    VALUES
    (
        'PLAN' + RIGHT('000' + CAST(@mp AS VARCHAR(10)), 3),
        'AST' + RIGHT('0000' + CAST(@mp AS VARCHAR(10)), 4),
        'MT' + RIGHT('000' + CAST(((@mp - 1) % 20) + 1 AS VARCHAR(10)), 3),
        DATEADD(DAY, -(@mp * 10), CAST(GETDATE() AS DATE)),
        DATEADD(DAY, @mp * 2, CAST(GETDATE() AS DATE)),
        'EMP' + RIGHT('000' + CAST(((@mp - 1) % 30) + 1 AS VARCHAR(10)), 3),
        1
    );

    SET @mp += 1;
END;
GO

-- =========================================================
-- 15. События ТО (40 записей)
-- =========================================================
DECLARE @me INT = 1;

WHILE @me <= 40
BEGIN
    INSERT INTO asset_mgmt.maintenance_events
    (
        event_code, asset_code, maintenance_type_code, event_date,
        performed_by_code, result_summary, cost_amount
    )
    VALUES
    (
        'EVT' + RIGHT('000' + CAST(@me AS VARCHAR(10)), 3),
        'AST' + RIGHT('0000' + CAST(@me AS VARCHAR(10)), 4),
        'MT' + RIGHT('000' + CAST(((@me - 1) % 20) + 1 AS VARCHAR(10)), 3),
        DATEADD(DAY, -(@me * 4), CAST(GETDATE() AS DATE)),
        'EMP' + RIGHT('000' + CAST(((@me - 1) % 30) + 1 AS VARCHAR(10)), 3),
        N'Проведено обслуживание, состояние удовлетворительное.',
        CAST(1500 + (@me * 150) AS DECIMAL(14,2))
    );

    SET @me += 1;
END;
GO

-- =========================================================
-- 16. Сессии инвентаризации (10 записей)
-- =========================================================
DECLARE @isess INT = 1;

WHILE @isess <= 10
BEGIN
    INSERT INTO asset_mgmt.inventory_sessions
    (
        session_code, session_name, location_code, start_date, end_date, lead_employee_code, session_status
    )
    VALUES
    (
        'SES' + RIGHT('000' + CAST(@isess AS VARCHAR(10)), 3),
        N'Плановая инвентаризация #' + CAST(@isess AS NVARCHAR(10)),
        'LOC' + RIGHT('000' + CAST(((@isess - 1) % 20) + 1 AS VARCHAR(10)), 3),
        DATEADD(DAY, -(@isess * 20), CAST(GETDATE() AS DATE)),
        DATEADD(DAY, -(@isess * 20) + 2, CAST(GETDATE() AS DATE)),
        'EMP' + RIGHT('000' + CAST(((@isess - 1) % 30) + 1 AS VARCHAR(10)), 3),
        N'Завершена'
    );

    SET @isess += 1;
END;
GO

-- =========================================================
-- 17. Результаты инвентаризации (50 записей)
-- =========================================================
DECLARE @ir INT = 1;

WHILE @ir <= 50
BEGIN
    INSERT INTO asset_mgmt.inventory_results
    (
        result_code, session_code, asset_code, actual_location_code, condition_note, comment_text
    )
    VALUES
    (
        'RES' + RIGHT('000' + CAST(@ir AS VARCHAR(10)), 3),
        'SES' + RIGHT('000' + CAST(((@ir - 1) % 10) + 1 AS VARCHAR(10)), 3),
        'AST' + RIGHT('0000' + CAST(@ir AS VARCHAR(10)), 4),
        'LOC' + RIGHT('000' + CAST(((@ir - 1) % 20) + 1 AS VARCHAR(10)), 3),
        CASE WHEN @ir % 5 = 0 THEN N'Требует проверки' ELSE N'Исправен' END,
        N'Результат тестовой инвентаризации.'
    );

    SET @ir += 1;
END;
GO

-- =========================================================
-- 18. Перемещения активов (40 записей)
-- =========================================================
DECLARE @mv INT = 1;

WHILE @mv <= 40
BEGIN
    DECLARE @from_num INT = ((@mv - 1) % 20) + 1;
    DECLARE @to_num INT = ((@mv) % 20) + 1;

    INSERT INTO asset_mgmt.asset_movements
    (
        movement_code, asset_code, from_location_code, to_location_code, movement_date,
        moved_by_code, accepted_by_code, document_code, basis
    )
    VALUES
    (
        'MOV' + RIGHT('000' + CAST(@mv AS VARCHAR(10)), 3),
        'AST' + RIGHT('0000' + CAST(@mv AS VARCHAR(10)), 4),
        'LOC' + RIGHT('000' + CAST(@from_num AS VARCHAR(10)), 3),
        'LOC' + RIGHT('000' + CAST(@to_num AS VARCHAR(10)), 3),
        DATEADD(DAY, -(@mv * 2), CAST(GETDATE() AS DATE)),
        'EMP' + RIGHT('000' + CAST(((@mv - 1) % 30) + 1 AS VARCHAR(10)), 3),
        'EMP' + RIGHT('000' + CAST(((@mv) % 30) + 1 AS VARCHAR(10)), 3),
        'DOC' + RIGHT('0000' + CAST(@mv AS VARCHAR(10)), 4),
        N'Перемещение между подразделениями'
    );

    SET @mv += 1;
END;
GO

-- =========================================================
-- 19. Представления
-- =========================================================
CREATE VIEW asset_mgmt.v_asset_full_info
AS
SELECT
    a.asset_code,
    a.asset_name,
    c.category_name,
    a.inventory_number,
    a.serial_number,
    a.acquisition_date,
    a.initial_cost,
    a.current_value,
    DATALENGTH(a.image) AS image_size_bytes,
    s.status_name,
    l.location_name,
    l.city,
    e.full_name AS responsible_person,
    d.department_name,
    v.vendor_name
FROM asset_mgmt.assets a
INNER JOIN asset_mgmt.asset_categories c
    ON c.category_code = a.category_code
INNER JOIN asset_mgmt.asset_statuses s
    ON s.status_code = a.status_code
INNER JOIN asset_mgmt.locations l
    ON l.location_code = a.location_code
INNER JOIN asset_mgmt.employees e
    ON e.employee_code = a.responsible_code
INNER JOIN asset_mgmt.departments d
    ON d.department_code = e.department_code
LEFT JOIN asset_mgmt.vendors v
    ON v.vendor_code = a.vendor_code;
GO

CREATE VIEW asset_mgmt.v_balance_report
AS
SELECT
    c.category_name,
    COUNT(*) AS asset_count,
    SUM(a.initial_cost) AS total_initial_cost,
    SUM(a.current_value) AS total_current_value,
    SUM(a.initial_cost - a.current_value) AS total_depreciation
FROM asset_mgmt.assets a
INNER JOIN asset_mgmt.asset_categories c
    ON c.category_code = a.category_code
GROUP BY c.category_name;
GO

-- =========================================================
-- 20. Права доступа
-- =========================================================
GRANT SELECT ON SCHEMA::asset_mgmt TO asset_user_role;
GO

GRANT SELECT, INSERT, UPDATE ON SCHEMA::asset_mgmt TO asset_manager_role;
GO

GRANT CONTROL ON SCHEMA::asset_mgmt TO asset_admin_role;
GO

-- =========================================================
-- 21. Проверочные запросы
-- =========================================================
SELECT COUNT(*) AS assets_count FROM asset_mgmt.assets;
SELECT COUNT(*) AS assets_with_image FROM asset_mgmt.assets WHERE image IS NOT NULL;
SELECT COUNT(*) AS categories_count FROM asset_mgmt.asset_categories;
SELECT COUNT(*) AS statuses_count FROM asset_mgmt.asset_statuses;
SELECT COUNT(*) AS locations_count FROM asset_mgmt.locations;
SELECT COUNT(*) AS vendors_count FROM asset_mgmt.vendors;
SELECT TOP 10 * FROM asset_mgmt.v_asset_full_info;
SELECT * FROM asset_mgmt.v_balance_report ORDER BY category_name;
GO
