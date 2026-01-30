<?php
$content = file_get_contents('diag_final.json');
// Remove BOM if present (powershell Out-File often adds it)
$content = preg_replace('/^\xEF\xBB\xBF/', '', $content);
$j = json_decode($content, true);
if (!$j) {
    echo "Failed to decode JSON. Error: " . json_last_error_msg() . "\n";
    echo "Content preview: " . substr($content, 0, 100) . "...\n";
    exit;
}
echo "Status: " . ($j['status'] ?? 'N/A') . "\n";
echo "Error: " . ($j['error'] ?? 'N/A') . "\n";
if (isset($j['config'])) {
    echo "MAIL_MAILER: " . $j['config']['mail_mailer'] . "\n";
    echo "MAIL_HOST: " . $j['config']['mail_host'] . "\n";
    echo "MAIL_PORT: " . $j['config']['mail_port'] . "\n";
    echo "MAIL_USER: " . $j['config']['mail_username'] . "\n";
    echo "MAIL_PASS_HINT: " . $j['config']['mail_password_hint'] . "\n";
    echo "FLW_KEYS SET: " . json_encode($j['config']['flw_keys_set']) . "\n";
    echo "LAST_MIGRATIONS: " . json_encode($j['config']['last_migrations']) . "\n";
} else {
    echo "Config not found in JSON.\n";
}
