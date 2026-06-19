<?php
// Download and save files to correct locations
$controllerUrl = 'https://raw.githubusercontent.com/hmanc/OLX/main/app/Http/Controllers/NotificationController.php';
$modelUrl = 'https://raw.githubusercontent.com/hmanc/OLX/main/app/Models/Notifications.php';

$controllerContent = file_get_contents($controllerUrl);
$modelContent = file_get_contents($modelUrl);

if ($controllerContent) {
    file_put_contents('/var/www/nofak/app/Http/Controllers/NotificationController.php', $controllerContent);
    echo "Controller saved\n";
}
if ($modelContent) {
    file_put_contents('/var/www/nofak/app/Models/Notifications.php', $modelContent);
    echo "Model saved\n";
}
echo "Done!\n";