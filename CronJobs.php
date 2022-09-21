<?php
/*
  CronJobs.php
  Gestion-server

  Created by Kevin Bertrand on 21/09/2022.
*/

$dbHost = getenv('DATABASE_HOST');
$dbPort = getenv('DATABASE_PORT');
$dbUser = getenv('DATABASE_USERNAME');
$dbPassword = getenv('DATABASE_PASSWORD');
$dbName = getenv('DATABASE_NAME');

$dbconn = pg_connect("host=$dbHost port=$dbPort dbname=$dbName user=$dbUser password=$dbPassword")
    or die('Could not connect: ' . pg_last_error()),

echo "ok";
?>