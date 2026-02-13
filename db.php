<?php
header("Content-Type: application/json");

$conn = new mysqli("localhost", "osarume.uwuilekhue", "Byakuran6996", "mobileapps_2026B_osarume_uwuilekhue");

if ($conn->connect_error) {
    echo json_encode([
        "success" => false,
        "error" => "Database connection failed"
    ]);
    exit;
}
?>
