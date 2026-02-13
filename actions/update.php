<?php
include("../db.php");

if (!isset($_POST['id']) || !isset($_POST['name']) || !isset($_POST['phone'])) {
    echo json_encode([
        "success" => false,
        "error" => "Missing parameters"
    ]);
    exit;
}

$id = intval($_POST['id']);
$name = $conn->real_escape_string($_POST['name']);
$phone = $conn->real_escape_string($_POST['phone']);

$conn->query("UPDATE students SET name='$name', phone='$phone' WHERE id=$id");

echo json_encode([
    "success" => true
]);
?>
