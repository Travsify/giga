<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Delivery;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Carbon\Carbon;

class RiderController extends Controller
{
    /**
     * Get dashboard stats for the authenticated rider.
     */
    public function getDashboardStats()
    {
        $user = Auth::user();
        $rider = $user->rider;

        if (!$rider) {
            return response()->json(['error' => 'Rider profile not found.'], 404);
        }

        $today = Carbon::today();

        // Calculate Today's Earnings (delivered today)
        $todaysEarnings = Delivery::where('rider_id', $rider->id)
            ->where('status', 'delivered')
            ->whereDate('delivered_at', $today)
            ->sum('fare');

        // Calculate Completed Jobs today
        $completedJobsToday = Delivery::where('rider_id', $rider->id)
            ->where('status', 'delivered')
            ->whereDate('delivered_at', $today)
            ->count();

        // Calculate Completion Rate (lifetime or monthly - using monthly for relevance)
        $totalAssignedMonth = Delivery::where('rider_id', $rider->id)
            ->whereMonth('created_at', Carbon::now()->month)
            ->count();
        
        $completedMonth = Delivery::where('rider_id', $rider->id)
            ->where('status', 'delivered')
            ->whereMonth('delivered_at', Carbon::now()->month)
            ->count();

        $completionRate = $totalAssignedMonth > 0 ? round(($completedMonth / $totalAssignedMonth) * 100) : 100;

        // Productivity Tips
        $tips = $this->getProductivityTips($completedJobsToday, $todaysEarnings);

        return response()->json([
            'status' => 'success',
            'data' => [
                'todays_earnings' => (float) $todaysEarnings,
                'completed_jobs_today' => $completedJobsToday,
                'completion_rate' => $completionRate,
                'shift_goal_target' => 100.00, // Hardcoded for now, could be dynamic in future
                'productivity_tips' => $tips,
                'currency' => $user->wallet ? $user->wallet->currency : 'GBP',
                'currency_symbol' => $user->currency_symbol ?? '£',
            ]
        ]);
    }

    /**
     * Generate simple dynamic tips.
     */
    private function getProductivityTips($jobs, $earnings)
    {
        $hour = Carbon::now()->hour;
        $tips = [];

        if ($jobs == 0) {
            $tips[] = "Start your shift! High demand areas are active now.";
        }

        if ($earnings < 50) {
            $tips[] = "Great start. Complete 3 more jobs to reach your half-day goal!";
        }

        if ($hour >= 11 && $hour <= 14) {
            $tips[] = "Lunch rush! Head to the city center for more deliveries.";
        } elseif ($hour >= 17 && $hour <= 20) {
            $tips[] = "Evening peak is here. Watch out for Priority requests.";
        }

        $tips[] = "Keep your battery charged and stay hydrated!";

        return $tips;
    }
}
