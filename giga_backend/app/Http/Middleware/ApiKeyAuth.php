<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use App\Models\ApiKey;
use Symfony\Component\HttpFoundation\Response;

class ApiKeyAuth
{
    /**
     * Handle an incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure  $next
     * @return \Symfony\Component\HttpFoundation\Response
     */
    public function handle(Request $request, Closure $next): Response
    {
        $header = $request->header('Authorization');
        if (!$header || !str_starts_with($header, 'Bearer ')) {
            return response()->json(['message' => 'Missing or invalid API Key.'], 401);
        }

        $plainKey = str_replace('Bearer ', '', $header);
        $hashedKey = hash('sha256', $plainKey);

        $apiKey = ApiKey::where('key', $hashedKey)
            ->where('is_active', true)
            ->first();

        if (!$apiKey) {
            return response()->json(['message' => 'Invalid or inactive API Key.'], 401);
        }

        // Tag the request with the business
        $request->merge(['external_business' => $apiKey->logisticsCompany]);
        
        // Update last used
        $apiKey->update(['last_used_at' => now()]);

        return $next($request);
    }
}
