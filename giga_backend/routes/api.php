<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DeliveryController;
use App\Http\Controllers\Api\ChatController;
use App\Http\Controllers\Api\ProfileController;
// use App\Http\Controllers\Api\NotificationController; // FIXME: Class does not exist

use App\Http\Controllers\Api\PasswordResetController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\TestMailController;
use App\Http\Controllers\Api\EmailVerificationController;
use App\Http\Controllers\Api\SubscriptionController;
use App\Http\Controllers\Api\BusinessController;
use App\Http\Controllers\Api\BulkBookingController;
use App\Http\Controllers\Api\PromoController;
use App\Http\Controllers\Api\LockerController;
use App\Http\Controllers\Api\SustainabilityController;
use App\Http\Controllers\Api\SettingsController;
// use App\Http\Controllers\Api\CurrencyController; // FIXME: Class does not exist
use App\Http\Controllers\Api\BankController;

\Illuminate\Support\Facades\Log::info('REQUEST: ' . request()->method() . ' ' . request()->fullUrl(), request()->all());

// Rate-limited auth routes (5 attempts per minute per IP)
Route::middleware('throttle:5,1')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::get('/ping', function() {
    return response()->json(['status' => 'pong', 'time' => now()->toDateTimeString(), 'debug' => config('app.debug')]);
});

Route::post('/login', [AuthController::class, 'login']);
    Route::post('/forgot-password', [PasswordResetController::class, 'sendResetLink']);
    Route::post('/reset-password', [PasswordResetController::class, 'reset']);
});

// App Settings (Public - no auth required)
Route::get('/settings', [SettingsController::class, 'index']);
Route::get('/settings/check-version/{version}', [SettingsController::class, 'checkVersion']);
Route::get('/v2/test', function() {
    return response()->json([
        'status' => 'live',
        'time' => now()->toDateTimeString(),
        'version' => 'v2'
    ]);
});

// Debug: Test registration without rate limiting
Route::post('/test-register', function(\Illuminate\Http\Request $request) {
    try {
        \Illuminate\Support\Facades\Log::info('TEST-REGISTER: Starting', $request->all());
        
        // Step 1: Validate
        $validator = \Illuminate\Support\Facades\Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8',
            'role' => 'required|in:Customer,Rider,Company',
        ]);

        if ($validator->fails()) {
            return response()->json(['step' => 'validation', 'errors' => $validator->errors()], 422);
        }

        // Step 2: Create user
        $user = \App\Models\User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => \Illuminate\Support\Facades\Hash::make($request->password),
            'role' => $request->role,
            'uk_phone' => $request->uk_phone ?? null,
            'country_code' => $request->country_code ?? 'GB',
            'currency_code' => $request->currency_code ?? 'GBP',
        ]);
        \Illuminate\Support\Facades\Log::info('TEST-REGISTER: User created', ['user_id' => $user->id]);

        // Step 3: Create rider if Rider role
        if ($request->role === 'Rider') {
            \App\Models\Rider::create([
                'user_id' => $user->id,
                'license_number' => 'PENDING-' . $user->id . '-' . time(),
                'vehicle_plate_number' => 'PENDING-' . $user->id . '-' . time(),
                'vehicle_type' => 'bike',
                'is_online' => false,
                'has_vehicle' => false,
                'vehicle_verified' => false,
            ]);
            \Illuminate\Support\Facades\Log::info('TEST-REGISTER: Rider created');
        }

        // Step 4: Create wallet
        \App\Models\Wallet::create([
            'user_id' => $user->id,
            'balance' => 0.00,
            'currency' => $user->currency_code ?? 'GBP',
        ]);
        \Illuminate\Support\Facades\Log::info('TEST-REGISTER: Wallet created');

        // Step 5: Create token
        $token = $user->createToken('auth_token')->plainTextToken;
        \Illuminate\Support\Facades\Log::info('TEST-REGISTER: Token created');

        return response()->json([
            'status' => 'success',
            'user' => $user,
            'token' => $token,
        ], 201);
    } catch (\Throwable $e) {
        \Illuminate\Support\Facades\Log::error('TEST-REGISTER Error: ' . $e->getMessage(), [
            'file' => $e->getFile(),
            'line' => $e->getLine(),
        ]);
        return response()->json([
            'status' => 'error',
            'step' => 'exception',
            'message' => $e->getMessage(),
            'file' => $e->getFile(),
            'line' => $e->getLine(),
        ], 500);
    }
});

Route::get('/db-debug', function() {
    return response()->json([
        'settings' => \App\Models\AppSetting::all(),
        'cache_driver' => config('cache.default'),
        'env' => [
            'MAIL_HOST' => env('MAIL_HOST'),
            'MAIL_USERNAME' => env('MAIL_USERNAME'),
            'FLW_PUBLIC_KEY' => env('FLW_PUBLIC_KEY'),
        ]
    ]);
});

Route::get('/countries', [App\Http\Controllers\Api\SettingsController::class, 'getCountries']);
Route::get('/currency-rates', [App\Http\Controllers\Api\SettingsController::class, 'getCurrencyRates']);
Route::get('/settings/payment', [App\Http\Controllers\Api\SettingsController::class, 'getPaymentConfig']);

// Payment (Public for Demo)
Route::post('/create-payment-intent-public', [PaymentController::class, 'createPaymentIntentPublic']);
Route::get('/diag', [PaymentController::class, 'diag']);
Route::get('/test-mail', [TestMailController::class, 'sendTestMail']);
Route::get('/test-view', [TestMailController::class, 'sendTestView']);
Route::get('/live-smtp-test', [TestMailController::class, 'liveSmtpTest']);
Route::get('/resend-diag', [TestMailController::class, 'resendDiag']);
Route::get('/test-sms', [TestMailController::class, 'sendTestSms']);
Route::get('/test-resend-service', [TestMailController::class, 'testResendService']);
Route::get('/env-check', [App\Http\Controllers\Api\TestMailController::class, 'envCheck']);
Route::get('/sync-mail-settings', [App\Http\Controllers\Api\TestMailController::class, 'syncMailSettings']);

Route::get('/live-resend-test', function() {
    $debug = [
        'mailers_resend' => config('mail.mailers.resend'),
        'services_resend' => config('services.resend'),
        'driver_class' => class_exists('Resend\Laravel\Transport\ResendTransportFactory'),
    ];

    if (empty($debug['mailers_resend'])) {
        return response()->json(['status' => 'error', 'message' => 'Resend Mailer Config Missing', 'debug' => $debug], 500);
    }
    
    try {
        $to = request('email', 'info@usegiga.site'); 
        
        \Illuminate\Support\Facades\Mail::mailer('resend')->raw('Live Resend Test', function ($message) use ($to) {
            $message->to($to)
                    ->subject('GIGA Live Resend Test');
        });

        return response()->json([
            'status' => 'success', 
            'message' => "Email sent to $to via Resend",
            'debug' => $debug
        ]);
    } catch (\Throwable $e) {
        return response()->json([
            'status' => 'error',
            'message' => $e->getMessage(),
            'file' => $e->getFile(),
            'line' => $e->getLine(),
            'debug' => $debug
        ], 500);
    }
});

// Route::get('/test-smtp', [App\Http\Controllers\Api\TestSmtpController::class, 'test']); // FIXME: Class does not exist
// Route::get('/currency-rates', [CurrencyController::class, 'getRates']); // FIXME: Class does not exist
// Route::get('/currencies', [CurrencyController::class, 'index']); // FIXME: Class does not exist
// SECRET: Force Migration (Delete after use!)
Route::get('/fix-migrations', function() {
    try {
        \Illuminate\Support\Facades\Artisan::call('migrate', ['--force' => true]);
        \Illuminate\Support\Facades\Artisan::call('db:seed', ['--class' => 'AppSettingsSeeder', '--force' => true]);
        return response()->json([
            'message' => 'Migrations and Settings updated successfully', 
            'output' => \Illuminate\Support\Facades\Artisan::output()
        ]);
    } catch (\Exception $e) {
        return response()->json(['error' => $e->getMessage()], 500);
    }
});

// NUCLEAR: Force-skip problematic migration then run remaining
Route::get('/force-skip-migration', function() {
    try {
        $migrationName = '2026_01_24_081054_add_email_to_email_verification_codes_table';
        
        // Step 1: Check if already marked as run
        $exists = \Illuminate\Support\Facades\DB::table('migrations')
            ->where('migration', $migrationName)
            ->exists();
        
        $status = ['migration' => $migrationName, 'already_in_table' => $exists];
            
        if (!$exists) {
            // Get the max batch number
            $maxBatch = \Illuminate\Support\Facades\DB::table('migrations')->max('batch') ?? 0;
            
            // Insert the migration as "already run"
            \Illuminate\Support\Facades\DB::table('migrations')->insert([
                'migration' => $migrationName,
                'batch' => $maxBatch + 1
            ]);
            $status['action'] = 'inserted';
        } else {
            $status['action'] = 'already_exists';
        }
        
        // Step 2: List all pending migrations (What would migrate run?)
        $allMigrations = \Illuminate\Support\Facades\DB::table('migrations')->pluck('migration')->toArray();
        $status['migrations_in_db'] = count($allMigrations);
        
        // Step 3: Now run remaining migrations
        \Illuminate\Support\Facades\Artisan::call('migrate', ['--force' => true]);
        $output = \Illuminate\Support\Facades\Artisan::output();
        
        // Step 4: Seed settings
        \Illuminate\Support\Facades\Artisan::call('db:seed', ['--class' => 'AppSettingsSeeder', '--force' => true]);
        
        return response()->json([
            'message' => 'Completed!',
            'status' => $status,
            'migrate_output' => $output
        ]);
    } catch (\Exception $e) {
        return response()->json([
            'error' => $e->getMessage(),
            'trace' => $e->getTraceAsString()
        ], 500);
    }
});



Route::get('/fix-schema-manual', function() {
    try {
        \Illuminate\Support\Facades\Schema::dropIfExists('email_verification_codes');
        
        \Illuminate\Support\Facades\Schema::create('email_verification_codes', function (\Illuminate\Database\Schema\Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id')->nullable(); // Correctly Nullable
            $table->string('email')->nullable()->index();
            $table->string('code', 7); // 7 digits
            $table->timestamp('expires_at');
            $table->timestamp('created_at')->nullable();
        });

        return response()->json(['message' => 'Table dropped and recreated successfully!']);
    } catch (\Exception $e) {
        return response()->json(['error' => $e->getMessage()], 500);
    }
});

Route::get('/direct-fix-settings', function() {
    try {
        $keys = [
            'flutterwave_public_key' => 'FLWPUBK-a1a7a1e074a86a64e6a3f57d89f4165c-X',
            'flutterwave_secret_key' => 'FLWSECK-fd0351a5fbf3d6e25438d75b1d069347-19c2b052fc9vt-X',
            'flutterwave_encryption_key' => 'fd0351a5fbf3696f229da328',
        ];

        foreach ($keys as $key => $value) {
            \App\Models\AppSetting::updateOrCreate(
                ['key' => $key],
                [
                    'key' => $key,
                    'value' => (string) $value,
                    'group' => 'payment',
                    'type' => 'string',
                    'is_public' => ($key === 'flutterwave_public_key'),
                    'is_sensitive' => ($key !== 'flutterwave_public_key'),
                ]
            );
        }
        
        \Illuminate\Support\Facades\Cache::flush();
        
        return response()->json(['message' => 'Settings updated successfully', 'current_keys_status' => [
            'public' => \App\Models\AppSetting::get('flutterwave_public_key') ? 'present' : 'missing',
            'secret' => \App\Models\AppSetting::get('flutterwave_secret_key') ? 'present' : 'missing',
        ]]);
    } catch (\Exception $e) {
        return response()->json(['error' => $e->getMessage()], 500);
    }
});
\Illuminate\Support\Facades\Log::info('API Routes loaded');

Route::post('/verify-vehicle', [App\Http\Controllers\Api\VehicleVerificationController::class, 'verify']);
Route::get('/view-logs', [App\Http\Controllers\Api\TestMailController::class, 'viewLogs']);
Route::get('/status', function() { return response()->json(['status' => 'online', 'version' => '1.2.8']); });

// SECRET: One-time Admin Provisioning Endpoint (Delete after use!)
Route::get('/provision-admin-giga2026secret', function() {
    $user = \App\Models\User::updateOrCreate(
        ['email' => 'admin@giga.com'],
        [
            'name' => 'Super Admin',
            'password' => \Illuminate\Support\Facades\Hash::make('GigaAdmin2026!'),
            'role' => 'SuperAdmin',
            'email_verified_at' => now(),
        ]
    );
    return response()->json(['success' => true, 'message' => 'Admin provisioned', 'user_id' => $user->id]);
});

// Debug Route
Route::get('/live-signup-debug', function() {
    try {
        $email = request('email', 'info@usegiga.site');
        $code = '1234567';
        \Illuminate\Support\Facades\Log::info("Debug Signup: Sending to $email");
        
        // TEST DB INSERT (This causes crash if user_id is not nullable)
        \Illuminate\Support\Facades\DB::table('email_verification_codes')->updateOrInsert(
            ['email' => $email],
            [
                'code' => $code,
                'expires_at' => now()->addMinutes(10),
                'created_at' => now(),
            ]
        );

        \Illuminate\Support\Facades\Mail::mailer('resend')->send([], [], function ($message) use ($email, $code) {
             $message->to($email)
                     ->subject('Debug OTP')
                     ->html("<h3>Code: $code</h3>");
        });
        
        return response()->json(['status' => 'success', 'message' => "Sent to $email via Controller Logic (DB+Mail)"]);
    } catch (\Throwable $e) {
        return response()->json([
            'status' => 'error',
            'message' => $e->getMessage(),
            'trace' => $e->getTraceAsString()
        ], 500);
    }
});

// Public Signup Verification
Route::post('/signup/verify-email/send', [EmailVerificationController::class, 'sendSignupCode']);
Route::post('/signup/verify-email/confirm', [EmailVerificationController::class, 'verifySignupCode']);
Route::post('/phone/send-otp', [App\Http\Controllers\Api\PhoneVerificationController::class, 'sendOtp']);
Route::post('/phone/verify-otp', [App\Http\Controllers\Api\PhoneVerificationController::class, 'verifyOtp']);

// Public Bank Lookup (for mobile app bank picker) - with debug
Route::get('/banks', function(\Illuminate\Http\Request $request) {
    try {
        $country = $request->query('country', 'NG');
        \Illuminate\Support\Facades\Log::info('Banks endpoint called', ['country' => $country]);
        
        // Check if AppSetting exists
        $secretKey = \App\Models\AppSetting::get('flutterwave_secret_key');
        \Illuminate\Support\Facades\Log::info('Secret key retrieved', ['has_key' => !empty($secretKey), 'key_prefix' => substr($secretKey ?? '', 0, 10)]);
        
        if (empty($secretKey)) {
            return response()->json(['error' => 'Flutterwave secret key not configured', 'debug' => 'Key is empty'], 500);
        }
        
        $flw = new \App\Services\FlutterwaveTransferService();
        $banks = $flw->getBanks($country);
        
        return response()->json([
            'status' => 'success',
            'data' => $banks
        ]);
    } catch (\Exception $e) {
        \Illuminate\Support\Facades\Log::error('Banks endpoint error: ' . $e->getMessage());
        return response()->json(['error' => $e->getMessage(), 'trace' => $e->getTraceAsString()], 500);
    }
});
Route::match(['get', 'post'], '/banks/resolve', [BankController::class, 'resolveAccount']);

// Flutterwave callback (public - handles redirect after payment)
Route::get('/wallet/flutterwave/callback', [App\Http\Controllers\Api\PaymentController::class, 'flutterwaveCallback']);


// Utility Routes for Deployment Diagnostics
Route::get('/clear-cache', function() {
    try {
        \Illuminate\Support\Facades\Artisan::call('optimize:clear');
        return response()->json([
            'status' => 'success', 
            'message' => 'Cache cleared (optimize:clear)',
            'output' => \Illuminate\Support\Facades\Artisan::output()
        ]);
    } catch (\Exception $e) {
        return response()->json(['error' => $e->getMessage()], 500);
    }
});

Route::get('/debug-config', function() {
    $config = config('mail');
    // Mask sensitive data
    if(isset($config['mailers']['smtp']['password'])) $config['mailers']['smtp']['password'] = '***';
    return response()->json([
        'mail_defaults' => $config,
        'env_vars' => [
            'MAIL_MAILER' => env('MAIL_MAILER'),
            'MAIL_HOST' => env('MAIL_HOST'),
            'MAIL_USERNAME' => env('MAIL_USERNAME'),
            'RESEND_API_KEY_SET' => !empty(env('RESEND_API_KEY')),
        ],
        'services_config' => [
            'resend_key_configured' => !empty(config('services.resend.key')),
        ],
        'is_cached' => app()->configurationIsCached(),
    ]);
});

// Protected routes
Route::middleware('auth:sanctum')->group(function () {
    // Auth
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);

    // Email Verification
    Route::post('/email/send-verification', [EmailVerificationController::class, 'sendVerificationCode']);
    Route::post('/email/verify', [EmailVerificationController::class, 'verifyCode']);
    Route::post('/email/resend', [EmailVerificationController::class, 'resendCode']);

    // Notifications
    // Route::get('/notifications', [NotificationController::class, 'index']); // FIXME: Class does not exist

    // Deliveries
    Route::get('/deliveries', [DeliveryController::class, 'index']);
    Route::post('/deliveries/estimate', [DeliveryController::class, 'estimateFare']);
    Route::post('/deliveries', [DeliveryController::class, 'create']);
    Route::post('/deliveries/{id}/proof', [DeliveryController::class, 'uploadProof']);
    Route::patch('/deliveries/{id}/status', [DeliveryController::class, 'updateStatus']);
    Route::post('/deliveries/{id}/accept', [DeliveryController::class, 'accept']);
    Route::get('/riders/nearby', [DeliveryController::class, 'getNearbyRiders']);

    // Incident Reporting
    Route::post('/incidents', [App\Http\Controllers\Api\IncidentController::class, 'store']);

    // Chat
    Route::get('/deliveries/{id}/messages', [ChatController::class, 'index']);
    Route::post('/deliveries/{id}/messages', [ChatController::class, 'store']);

    // Profile & Loyalty
    Route::get('/profile', [ProfileController::class, 'show']);
    Route::patch('/profile', [ProfileController::class, 'update']);
    Route::get('/loyalty', [ProfileController::class, 'loyaltyInfo']);
    Route::post('/referral/submit', [ProfileController::class, 'submitReferral']);
    Route::patch('/profile/rider', [ProfileController::class, 'updateRiderStatus']);
    Route::post('/profile/vehicle-document', [App\Http\Controllers\Api\VehicleVerificationController::class, 'uploadDocument']);
    Route::get('/rider/dashboard-stats', [App\Http\Controllers\Api\RiderController::class, 'getDashboardStats']);
    Route::get('/rider/history', [App\Http\Controllers\Api\RiderController::class, 'getHistory']);
    Route::get('/rider/active-job', [App\Http\Controllers\Api\RiderController::class, 'getActiveJob']);
    
    // Vehicles
    Route::apiResource('vehicles', App\Http\Controllers\Api\VehicleController::class);
    Route::post('/vehicles/{id}/activate', [App\Http\Controllers\Api\VehicleController::class, 'activate']);

    // Banks
    Route::get('/rider/banks', [BankController::class, 'index']);
    Route::post('/rider/banks', [BankController::class, 'store']);
    Route::put('/rider/banks/{id}', [BankController::class, 'update']);
    Route::delete('/rider/banks/{id}', [BankController::class, 'destroy']);
    // Route::get('/banks', [BankController::class, 'getBanks']); // Moved to public routes
    // Route::get('/banks/resolve', [BankController::class, 'resolveAccount']); // Moved to public routes

    // Payments
    Route::post('/create-payment-intent', [App\Http\Controllers\Api\PaymentController::class, 'createPaymentIntent']);
    Route::post('/payment/confirm', [App\Http\Controllers\Api\PaymentController::class, 'confirmPayment']);
    Route::post('/wallet/redeem', [App\Http\Controllers\Api\PaymentController::class, 'redeem']);
    Route::post('/wallet/withdraw', [App\Http\Controllers\Api\PaymentController::class, 'withdraw']);
    Route::get('/wallet/transactions', [App\Http\Controllers\Api\PaymentController::class, 'getTransactions']);
    Route::post('/wallet/flutterwave/create', [App\Http\Controllers\Api\PaymentController::class, 'createFlutterwavePayment']);
    Route::post('/wallet/flutterwave/verify', [App\Http\Controllers\Api\PaymentController::class, 'verifyFlutterwavePayment']);
    Route::post('/wallet/transfer', [App\Http\Controllers\Api\PaymentController::class, 'transfer']);
    Route::post('/wallet/giftcard/purchase', [App\Http\Controllers\Api\PaymentController::class, 'purchaseGiftCard']);

    // Bill Payments
    Route::get('/bills/categories', [App\Http\Controllers\Api\BillPaymentController::class, 'getCategories']);
    Route::post('/bills/validate', [App\Http\Controllers\Api\BillPaymentController::class, 'validateCustomer']);
    Route::post('/bills/pay', [App\Http\Controllers\Api\BillPaymentController::class, 'pay']);

    // Subscriptions
    Route::get('/subscription/status', [App\Http\Controllers\Api\SubscriptionController::class, 'status']);
    Route::post('/subscription/subscribe', [App\Http\Controllers\Api\SubscriptionController::class, 'subscribe']);
    Route::post('/subscription/cancel', [App\Http\Controllers\Api\SubscriptionController::class, 'cancel']);

    // Business (B2B)
    Route::post('/business/enroll', [BusinessController::class, 'enroll']);
    Route::get('/business/profile', [BusinessController::class, 'getProfile']);
    Route::get('/business/team', [BusinessController::class, 'getTeam']);
    Route::post('/business/invite', [BusinessController::class, 'inviteMember']);
    Route::get('/business/billing', [BusinessController::class, 'getBilling']);
    Route::get('/business/stats', [BusinessController::class, 'getStats']);
    Route::get('/business/activity', [BusinessController::class, 'getRecentActivity']);
    Route::post('/business/bulk-book', [BulkBookingController::class, 'processBatch']);
    
    // Placeholder for API Keys
    Route::post('/business/api-keys', function() { return response()->json(['token' => 'mock_token_' . time()]); });

    // Promos & Offers
    Route::get('/promos', [App\Http\Controllers\Api\PromoController::class, 'index']);
    Route::post('/promos/validate', [App\Http\Controllers\Api\PromoController::class, 'validateCode']);

    // Lockers
    Route::get('/lockers', [App\Http\Controllers\Api\LockerController::class, 'index']);
    Route::get('/lockers/{id}', [App\Http\Controllers\Api\LockerController::class, 'show']);

    // Sustainability / Carbon Impact
    Route::get('/sustainability/stats', [App\Http\Controllers\Api\SustainabilityController::class, 'getStats']);

    // Inter-state Delivery
    // Route::get('/inter-state/price', [App\Http\Controllers\Api\InterStateController::class, 'getPrice']); // FIXME: Class does not exist
    // Route::post('/inter-state/waybill', [App\Http\Controllers\Api\InterStateController::class, 'createWaybill']); // FIXME: Class does not exist

    // Shop & Ship
    // Route::get('/shop-and-ship/address', [App\Http\Controllers\Api\ShopAndShipController::class, 'getAddress']); // FIXME: Class does not exist
    // Route::get('/shop-and-ship/packages', [App\Http\Controllers\Api\ShopAndShipController::class, 'getPackages']); // FIXME: Class does not exist
});
