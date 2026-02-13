<?php
include("../db.php");

if (!isset($_POST['name']) || !isset($_POST['phone'])) {
    echo json_encode([
        "success" => false,
        "error" => "Missing parameters"
    ]);
    exit;
}

$name = $conn->real_escape_string($_POST['name']);
$phone = $conn->real_escape_string($_POST['phone']);

$conn->query("INSERT INTO students (name, phone) VALUES ('$name', '$phone')");

echo json_encode([
    "success" => true,
    "data" => ["id" => $conn->insert_id]
]);
?>
