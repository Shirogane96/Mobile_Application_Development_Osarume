<?php
include("../db.php");

if (!isset($_POST['id'])) {
    echo json_encode([
        "success" => false,
        "error" => "ID required"
    ]);
    exit;
}

$id = intval($_POST['id']);

$conn->query("DELETE FROM students WHERE id=$id");

echo json_encode([
    "success" => true
]);
?>
