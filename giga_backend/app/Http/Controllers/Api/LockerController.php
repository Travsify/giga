<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Locker;
use Illuminate\Http\Request;

class LockerController extends Controller
{
    public function index(Request $request)
    {
        $country = $request->query('country', 'GB');
        return response()->json(Locker::where('country_code', $country)->get());
    }

    public function show($id)
    {
        return response()->json(Locker::findOrFail($id));
    }
}
