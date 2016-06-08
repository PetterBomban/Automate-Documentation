<?php
  
  include_once "./dbconn.php";

  if (isset($_GET['server']))
  {
    $server = $_GET['server'];
    $tables = $_GET['table'];
  }
  else
  {
    echo "Not allowed.";
    exit();
  }

  // List of columns
  function createTableHeaders($dataArray)
  {
    echo "<tr>\r\n";
    foreach ($dataArray as $data)
    {
      echo "<th>" . $data . "</th>";
    }
    echo "</tr>\r\n";
  }

  //The database, the table in the database and the list of columns
  function loadFromDatabase($database, $table, $dataArray)
  {
    $sql = "SELECT * FROM ${table} WHERE _id = '{$_GET['server']}'";
    $query = $database->query($sql);
    
    while($row = $query->fetchArray(SQLITE3_ASSOC)){
      echo "<tr id=$table>\r\n";
      foreach ($dataArray as $data)
      {
        echo "<td>". $row[$data] . "</td> \r\n";
      }
      echo "</tr>\r\n";
    }
  }
?>

<!DOCTYPE HTML>
<html>

  <head>
    <title><?php echo $server; ?></title>
    <link rel="stylesheet" href="./main.css">
  </head>

  <body>

    <table>
      <?php
        // Headers and values to load from db
        $serversList = array("_id", "Hostname", "IPAddress", "OS", "Installed", "Date");

        // Create table
        createTableHeaders($serversList);
        loadFromDatabase($db, $tables, $serversList);
      ?>
    </table>

  </body>

</html>

<?php
  $db->close();
?>