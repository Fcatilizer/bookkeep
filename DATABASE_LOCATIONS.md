# BookKeep Database Locations

## Overview

BookKeep uses SQLite for local data storage. The database location varies by platform to ensure optimal write permissions and data security.

## Database Locations by Platform

### Desktop Platforms (Windows, macOS, Linux)

- **Location**: `Documents/BookKeep/bookkeep.db`
- **Full Windows Path**: `C:\Users\{Username}\Documents\BookKeep\bookkeep.db`
- **Full macOS Path**: `/Users/{Username}/Documents/BookKeep/bookkeep.db`
- **Full Linux Path**: `/home/{Username}/Documents/BookKeep/bookkeep.db`

### Mobile Platforms (Android, iOS)

- **Location**: Standard app database directory (managed by Flutter)
- **Android**: `/data/data/com.ashish.bookkeep/databases/bookkeep.db`
- **iOS**: App sandbox database directory

## Why Different Locations?

### Desktop Platforms

- **Problem**: When apps are installed via installers (like Inno Setup), the default database path might not have write permissions
- **Solution**: Use Documents directory which always has user write permissions
- **Benefits**:
  - Guaranteed write access after installation
  - User can easily find and backup database files
  - No permission issues with Windows User Account Control (UAC)

### Mobile Platforms

- Use standard Flutter database paths which are optimized for mobile app sandboxing
- Managed by the operating system for security and data isolation

## Database Migration

The app automatically handles migration from old database locations:

1. **First Run After Update**: App checks for existing database in old location
2. **Migration**: If found, copies database to new location
3. **Preservation**: Old database is kept for safety (can be manually deleted)
4. **Seamless**: Users don't lose any existing data

## Troubleshooting

### Issue: "sqlite_error: 14" or "unable to open database file"

- **Cause**: Write permission issues with database location
- **Solution**: This is fixed with the new database location system
- **Action**: Update to latest version with new database paths

### Issue: Missing data after app update

- **Check**: Look for `bookkeep.db` in old location
- **Location**: App's default database directory
- **Solution**: Database migration should handle this automatically

### Manual Database Location

If you need to find your database manually:

**Windows**:

```
C:\Users\{YourUsername}\Documents\BookKeep\bookkeep.db
```

**macOS**:

```
/Users/{YourUsername}/Documents/BookKeep/bookkeep.db
```

**Linux**:

```
/home/{YourUsername}/Documents/BookKeep/bookkeep.db
```

## Backup Recommendations

1. **Built-in Backup**: Use the app's "Data Privacy" → "Backup Database" feature
2. **Manual Backup**: Copy the `bookkeep.db` file from the locations above
3. **Regular Backups**: Backup before major updates or data imports
4. **Cloud Sync**: Consider syncing the Documents/BookKeep folder to cloud storage

## Development Notes

- Database schema version: 9 (as of latest update)
- Cross-platform compatibility maintained
- Foreign key constraints enabled for data integrity
- Automatic migration system for seamless updates

---

**Last Updated**: September 24, 2025  
**Version**: Compatible with BookKeep v1.0.0+
