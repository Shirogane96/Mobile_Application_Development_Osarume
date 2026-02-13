<?php
include("../db.php");

$result = $conn->query("SELECT * FROM students");

$students = [];

while ($row = $result->fetch_assoc()) {
    $students[] = $row;
}

echo json_encode([
    "success" => true,
    "data" => $students
]);
?>
