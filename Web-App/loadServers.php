<?php

  include_once "dbconn.php";

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
    $sql = 'SELECT * FROM ' . $table;
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
  <table>
    <?php
      // Headers and values to load from db
      $serversList = array("Hostname", "IPAddress", "OS", "Date");

      // Create table
      createTableHeaders($serversList);
      loadFromDatabase($db, "link", $serversList);
      loadFromDatabase($db, "servers", $serversList);
    ?>
  </table>

<?php
  $db->close();
?>
