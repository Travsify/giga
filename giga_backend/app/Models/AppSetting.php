<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Cache;

class AppSetting extends Model
{
    protected $fillable = [
        'group',
        'key',
        'value',
        'type',
        'label',
        'description',
        'is_public',
        'is_sensitive',
    ];

    protected $casts = [
        'is_public' => 'boolean',
        'is_sensitive' => 'boolean',
    ];

    /**
     * Get a setting value by key
     */
    public static function get(string $key, $default = null)
    {
        $setting = Cache::remember("app_setting_{$key}", 3600, function () use ($key) {
            return static::where('key', $key)->first();
        });

        if (!$setting) {
            return $default;
        }

        return static::castValue($setting->value, $setting->type);
    }

    /**
     * Set a setting value
     */
    public static function set(string $key, $value, ?string $group = null): void
    {
        $setting = static::where('key', $key)->first();

        if ($setting) {
            $setting->update(['value' => static::prepareValue($value, $setting->type)]);
        } elseif ($group) {
            static::create([
                'key' => $key,
                'value' => is_array($value) || is_object($value) ? json_encode($value) : $value,
                'group' => $group,
                'type' => is_array($value) ? 'json' : (is_bool($value) ? 'boolean' : 'string'),
            ]);
        }

        Cache::forget("app_setting_{$key}");
        Cache::forget('app_settings_public');
    }

    /**
     * Get all public settings for mobile app
     */
    public static function getPublicSettings(): array
    {
        return Cache::remember('app_settings_public', 3600, function () {
            $settings = static::where('is_public', true)->get();
            
            $result = [];
            foreach ($settings as $setting) {
                $result[$setting->key] = static::castValue($setting->value, $setting->type);
            }
            
            return $result;
        });
    }

    /**
     * Get all settings grouped
     */
    public static function getAllGrouped(): array
    {
        $settings = static::orderBy('group')->orderBy('key')->get();
        
        $grouped = [];
        foreach ($settings as $setting) {
            $grouped[$setting->group][$setting->key] = [
                'value' => static::castValue($setting->value, $setting->type),
                'type' => $setting->type,
                'label' => $setting->label,
                'is_sensitive' => $setting->is_sensitive,
            ];
        }
        
        return $grouped;
    }

    /**
     * Cast value to appropriate type
     */
    protected static function castValue($value, string $type)
    {
        return match ($type) {
            'boolean' => filter_var($value, FILTER_VALIDATE_BOOLEAN),
            'integer' => (int) $value,
            'decimal' => (float) $value,
            'json' => is_string($value) ? json_decode($value, true) : $value,
            default => $value,
        };
    }

    /**
     * Prepare value for storage
     */
    protected static function prepareValue($value, string $type): string
    {
        if ($type === 'json' && (is_array($value) || is_object($value))) {
            return json_encode($value);
        }
        if ($type === 'boolean') {
            return $value ? '1' : '0';
        }
        return (string) $value;
    }
}
