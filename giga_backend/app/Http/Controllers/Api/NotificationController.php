<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(Request $request)
    {
        // Future: Return $request->user()->notifications;
        // For now, return empty list to avoid mock data
        return response()->json([]);
    }
}
