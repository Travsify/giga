<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Locker;
use Illuminate\Http\Request;

class LockerController extends Controller
{
    public function index()
    {
        return response()->json(Locker::all());
    }

    public function show($id)
    {
        return response()->json(Locker::findOrFail($id));
    }
}
