<!DOCTYPE html>

<html>

  <head>
    <title>Documentation</title>
    <link rel="stylesheet" href="http://localhost/main.css">
  </head>

  <body>

    <h2 id="header" class="serversHeader">Servers</h2>

    <div id="table"></div>

    <h2 id="header" class>Test</h2>

  </body>

  <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js"></script>

  <script>
    $(document).ready(function(){
      $('.serversHeader').click(function(){
        $('#table').toggle();
      });
    });
  </script>

  <script type="text/javascript">
    $("document").ready(function() {
      $('#table').load('loadServers.php');
    });
  </script>

</html>