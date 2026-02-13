-- Mobile Application Development Lab 2 Database Schema

CREATE TABLE IF NOT EXISTS students (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sample Data
INSERT INTO students (name, phone) VALUES
('Osarume Uwuilekhue', '08012345678'),
('Ada Lovelase', '08087654321'),
('Michael Johan', '08091234567'),
('Femi Adelola', '08056789012'),
('Lala Imbo', '08043210987');
